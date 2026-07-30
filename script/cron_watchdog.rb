# cron_watchdog.rb -- notices when a cron job stops running, and emails about it.
#
# WHY THIS EXISTS
# On 2026-07-26 we found that every app cron job on production had been failing on
# every single run since the Ruby 3.2.11 upgrade twelve days earlier -- and for some
# of them, much longer. The moon mailings, the digest mail, bounce handling and the
# sys_data refresh were all dead. Nothing noticed, because the only evidence was
# ~1.8 GB of error text in /tmp that nobody reads. This script is the thing that
# would have caught it within the hour.
#
# HOW IT DECIDES A JOB IS DEAD
# Log file mtime, not database state. Every job below prints something on every run
# (at minimum the VOH_DISCUSSION_ID warning), so an advancing mtime is a reliable
# heartbeat and a stale one means the job is not running.
#
#   Do NOT be tempted to use SysDatum#updated_at as the heartbeat instead. It looks
#   perfect and it is not: update_system.rb writes cur_moon_id, moon_new_or_full,
#   together_apart, moon_startdate and moon_enddate, all of which are CONSTANT within
#   a moon period, so `save!` is a no-op and updated_at legitimately sits still for
#   ~14 days at a time. (It only appeared to be a good signal during the outage
#   because, with the moons table exhausted, moon_enddate was being recalculated to
#   end-of-day on every run.)
#
# It also greps the tail of each log for failure signatures, which catches the other
# shape of this problem: the job runs on schedule but dies on startup every time.
#
# ALERTING
# Mails via the app's configured Postmark delivery, reusing the address that
# ExceptionNotification already reports to (config/environments/production.rb).
# State is kept in shared/log/cron_watchdog.state.json so it alerts on transitions
# rather than every hour: once when things break, a reminder every REMIND_HOURS while
# still broken, and once when they recover.
#
# KNOWN LIMITATION -- read this before trusting it
# Nothing watches the watchdog. If this script stops running, or Rails stops booting,
# it goes quiet and silence looks identical to health. The only real fix is a check
# from OUTSIDE the box (an uptime service, or another host reading
# shared/log/cron_watchdog.status). Until that exists, treat a long gap in
# cron_watchdog.log as suspicious in its own right.
#
# Usage:
#   rails-less:  ruby /abs/path/script/cron_watchdog.rb [options]
#   --dry-run      report only, never send mail
#   --test-alert   force an alert email regardless of status (for verifying delivery)
#   --quiet        no stdout (cron uses this; the log file is the record)

require_relative 'cron_helper'
require 'json'

DRY_RUN    = ARGV.include?('--dry-run')
TEST_ALERT = ARGV.include?('--test-alert')
QUIET      = ARGV.include?('--quiet')

LOG_DIR      = File.expand_path('../log', __dir__)
STATE_FILE   = File.join(LOG_DIR, 'cron_watchdog.state.json')
STATUS_FILE  = File.join(LOG_DIR, 'cron_watchdog.status')
OWN_LOG      = File.join(LOG_DIR, 'cron_watchdog.log')
REMIND_HOURS = 12
TAIL_BYTES   = 20_000

ALERT_TO   = ENV['CRON_WATCHDOG_TO'].presence || 'ffunch@cr8.com'
ALERT_FROM = defined?(SYSTEM_SENDER) ? SYSTEM_SENDER : 'questions@intermix.org'

# max_age is deliberately generous -- a couple of missed runs, not one, so a slow
# batch or a single blip does not page anybody.
JOBS = [
  { name: 'update_system',         log: 'cron_update_system.log',    schedule: 'every 10 min', max_age_min: 30 },
  { name: 'mail_moon',             log: 'cron_mail_moon.log',        schedule: 'every 15 min', max_age_min: 45 },
  { name: 'mail_send',             log: 'cron_mail_send.log',        schedule: 'daily 00:10',  max_age_min: 26 * 60 },
  { name: 'postmark_bounces',      log: 'cron_postmark_bounces.log', schedule: 'daily 13:13',  max_age_min: 26 * 60 },
  { name: 'follow_mutual',         log: 'cron_follow_mutual.log',    schedule: 'daily 01:01',  max_age_min: 26 * 60 },
  { name: 'activitypub_responses', log: 'activitypub_responses.log', schedule: 'every 2 min',  max_age_min: 15 },
  { name: 'activitypub_delivery',  log: 'activitypub_delivery.log',  schedule: 'every 2 min',  max_age_min: 15 },
].freeze

# Signatures of a job that runs but dies. Kept narrow on purpose: the logs carry a
# harmless "already initialized constant VOH_DISCUSSION_ID" warning on every run, and
# a watchdog that cries wolf gets ignored, which is how we got here.
ERROR_SIGNATURES = [
  /rbenv: version .* is not installed/,     # the 2026-07-14 failure, exactly
  /cannot load such file/,                  # the require File.dirname trap
  /bundler: failed to load command/,
  /Gem::LoadError/,
  /Mysql2::Error/,
  /\b(?:LoadError|NameError|NoMethodError|ArgumentError|TypeError)\b/,
  /command not found/,
].freeze

# `e-mail delivery problem` is deliberately NOT in the list above. It is a PER-RECIPIENT
# message, and on 2026-07-30 four suppressed addresses out of 44 successful sends flagged
# the whole job BAD -- precisely the cry-wolf behaviour this watchdog is supposed to avoid.
# The mailers print a job-level summary instead ("23 daily messages sent. 2 errors"), which
# is the right thing to judge: a handful of bad addresses is normal operation, everything
# failing is not. Partial failures are surfaced in the report without triggering an alert.
SEND_SUMMARY = /(\d+) (\w+) messages sent\. (\d+) errors/.freeze

# Fraction of failed sends that means "broken" rather than "some addresses are bad".
SEND_FAILURE_RATIO = 0.5

def load_state
  return {} unless File.exist?(STATE_FILE)
  JSON.parse(File.read(STATE_FILE))
rescue JSON::ParserError
  {}   # corrupt state must not take the watchdog down
end

def save_state(state)
  File.write(STATE_FILE, JSON.pretty_generate(state))
end

def tail_of(path)
  File.open(path) do |f|
    f.seek(-[TAIL_BYTES, f.size].min, IO::SEEK_END)
    f.read
  end
rescue SystemCallError
  ''
end

now      = Time.now.utc
state    = load_state
first_run = state['first_seen'].nil?
state['first_seen'] ||= now.iso8601
first_seen = Time.parse(state['first_seen'])

results = JOBS.map do |job|
  path = File.join(LOG_DIR, job[:log])
  r = job.merge(errors: [], notes: [])

  if File.exist?(path)
    age_min = ((now - File.mtime(path).utc) / 60.0).round
    r[:age_min] = age_min
    r[:status]  = age_min > job[:max_age_min] ? 'STALE' : 'ok'

    tail = tail_of(path)
    ERROR_SIGNATURES.each do |sig|
      hit = tail.each_line.reverse_each.find { |l| l =~ sig }
      r[:errors] << hit.strip[0, 200] if hit
    end
    r[:status] = 'ERRORS' if r[:status] == 'ok' && r[:errors].any?

    # Job-level send summaries, for the mailers. Only a majority-failure counts as broken;
    # a few suppressed or malformed addresses is normal and must not page anyone.
    tail.scan(SEND_SUMMARY).each do |sent, kind, errs|
      sent = sent.to_i
      errs = errs.to_i
      next if errs.zero?

      total = sent + errs
      if total.positive? && errs.to_f / total >= SEND_FAILURE_RATIO
        r[:errors] << "#{kind}: #{errs} of #{total} sends failed"
        r[:status] = 'ERRORS' unless r[:status] == 'STALE'
      else
        r[:notes] << "#{errs} #{kind} send error#{'s' if errs != 1} (of #{total})"
      end
    end
  else
    # No log yet. Only a problem once enough time has passed that the job really
    # should have run -- otherwise every freshly-installed daily job alerts at once.
    waited_min = ((now - first_seen) / 60.0).round
    r[:age_min] = nil
    r[:status]  = waited_min > job[:max_age_min] ? 'MISSING' : 'pending'
  end

  r
end

bad     = results.reject { |r| %w[ok pending].include?(r[:status]) }
status  = bad.empty? ? 'OK' : 'BAD'
host    = defined?(BASEDOMAIN) ? BASEDOMAIN : `hostname`.strip

table = results.map do |r|
  age = r[:age_min].nil? ? 'never' : "#{r[:age_min]}m ago"
  line = format('  %-22s %-16s %-9s %s', r[:name], r[:schedule], r[:status], age)
  line += "  [#{r[:notes].join('; ')}]" if r[:notes].any?
  line += "\n" + r[:errors].map { |e| "      ! #{e}" }.join("\n") if r[:errors].any?
  line
end.join("\n")

summary = "#{status} #{bad.size}/#{results.size} failing" \
          "#{bad.empty? ? '' : ' (' + bad.map { |b| b[:name] }.join(', ') + ')'}"

File.open(OWN_LOG, 'a') { |f| f.puts "#{now.iso8601} #{summary}" }
File.write(STATUS_FILE, "#{status}\n#{now.iso8601}\n#{summary}\n\n#{table}\n")
puts "#{now.iso8601} #{summary}\n#{table}" unless QUIET

# ---- decide whether to mail ----
prev        = state['status']
last_mail   = state['last_email_at'] ? Time.parse(state['last_email_at']) : nil
remind_due  = last_mail.nil? || (now - last_mail) > REMIND_HOURS * 3600

reason =
  if TEST_ALERT                                then 'test'
  elsif status == 'BAD' && prev != 'BAD'       then 'newly broken'
  elsif status == 'BAD' && remind_due          then 'still broken'
  elsif status == 'OK'  && prev == 'BAD'       then 'recovered'
  end

# Never alert on the very first run: there is no baseline to compare against, and
# pending daily jobs would look like failures.
reason = nil if first_run && !TEST_ALERT

if reason && !DRY_RUN
  subject = case reason
            when 'recovered' then "[InterMix Cron] RECOVERED on #{host}"
            when 'test'      then "[InterMix Cron] watchdog test on #{host}"
            else                  "[InterMix Cron] #{bad.size} job(s) not running on #{host}"
            end

  body = <<~BODY
    Cron watchdog on #{host} at #{now.iso8601} -- #{reason}.

    #{summary}

    #{table}

    Staleness is judged by each job's log mtime in shared/log/, because every job
    prints on every run. A STALE or MISSING job is not running at all; ERRORS means
    it runs on schedule but is failing.

    First thing to check, since it is what bit us on 2026-07-26:
      crontab -l                     # as ploy -- are the lines still there?
      ls -la /home/apps/intermix/shared/log/cron_*.log
      tail -40 <the stale job's log>
    App cron must run as ploy, never root: root's rbenv has no 3.2.11.
    See config/app_crontab.example.

    Watchdog state: #{STATE_FILE}
    Full status:    #{STATUS_FILE}
    This alert repeats at most every #{REMIND_HOURS}h while broken.
  BODY

  begin
    ActionMailer::Base.mail(
      from: ALERT_FROM, to: ALERT_TO,
      subject: subject, body: body
    ).deliver_now
    state['last_email_at'] = now.iso8601
    puts "  alert emailed to #{ALERT_TO} (#{reason})" unless QUIET
    File.open(OWN_LOG, 'a') { |f| f.puts "#{now.iso8601}   -> emailed #{ALERT_TO} (#{reason})" }
  rescue StandardError => e
    # Mail failing must not take the watchdog down -- the log and status file still record it.
    File.open(OWN_LOG, 'a') { |f| f.puts "#{now.iso8601}   -> EMAIL FAILED: #{e.class}: #{e.message}" }
    warn "alert email FAILED: #{e.class}: #{e.message}" unless QUIET
  end
elsif reason && DRY_RUN
  puts "  would email #{ALERT_TO} (#{reason}) -- suppressed by --dry-run" unless QUIET
end

state['status'] = status
state['checked_at'] = now.iso8601
save_state(state)
