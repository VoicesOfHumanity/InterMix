#-- postmark_bounces.rb --- stop mailing addresses Postmark refuses to deliver to.
#--
#-- Sets no_email + no_email_reason on any participant whose address is on the Postmark
#-- SUPPRESSION LIST for the message stream this app sends on. Without this, every digest
#-- run re-attempts delivery to dead addresses, Postmark rejects each one, and recipients
#-- who unsubscribed keep being mailed at.
#--
#-- REWRITTEN 2026-07-30. The old version asked
#--   GET /bounces?type=HardBounce&inactive=true&count=50&offset=0
#-- which was wrong in three compounding ways, and had been quietly missing almost
#-- everything for years:
#--
#--   1. WRONG ENDPOINT. /bounces is the bounce activity feed, not the suppression list.
#--      On 2026-07-30 it returned ONE record while the broadcast-stream suppression list
#--      held 238. Suppressions in Postmark are per-message-stream, and only the
#--      /message-streams/<id>/suppressions/dump endpoint reports them.
#--   2. type=HardBounce ONLY. Postmark also suppresses for SpamComplaint and
#--      ManualSuppression -- and on a broadcast stream, ManualSuppression with
#--      Origin=Recipient is HOW AN UNSUBSCRIBE IS RECORDED. Filtering to HardBounce
#--      meant unsubscribes were never honoured locally. That is the serious one.
#--   3. count=50, offset=0, NO PAGINATION. Anything past the first 50 was invisible.
#--
#-- Net effect when this was found: 102 of the 609 participants in the digest audience
#-- were still flagged mailable despite being suppressed -- 180 hard bounces, 15 spam
#-- complaints and 43 unsubscribes on the stream the app sends on.
#--
#-- The dump endpoint returns the whole list in one response, so there is no pagination
#-- to get wrong here.
#--
#-- Usage:
#--   ruby /abs/path/script/postmark_bounces.rb [--dry-run] [--all-streams]
#--     --dry-run       report what would change, write nothing
#--     --all-streams   sync every stream on the account, not just the configured one

require_relative 'cron_helper'
require 'net/http'
require 'openssl'
require 'json'

DRY_RUN     = ARGV.include?('--dry-run')
ALL_STREAMS = ARGV.include?('--all-streams')

def postmark_get(path)
  uri = URI("https://api.postmarkapp.com#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri)
  request['X-Postmark-Server-Token'] = Rails.application.credentials.postmark[:api_key]
  request['Accept'] = 'application/json'
  response = http.request(request)
  unless response.code.to_i == 200
    raise "Postmark GET #{path} returned HTTP #{response.code}: #{response.body.to_s[0, 300]}"
  end

  JSON.parse(response.body)
end

# The stream the app actually sends on -- being suppressed on a stream we never use would
# not affect deliverability, so that is the one that matters by default.
configured = Rails.application.config.action_mailer.postmark_settings.to_h[:message_stream]
configured ||= 'broadcast-stream'

streams =
  if ALL_STREAMS
    postmark_get('/message-streams')['MessageStreams'].to_a.map { |s| s['ID'] }
  else
    [configured]
  end

puts "Syncing suppressions from stream(s): #{streams.join(', ')}#{DRY_RUN ? ' (DRY RUN)' : ''}"

num_removed = 0
total_suppressed = 0
unmatched = 0
failed = 0

streams.each do |stream|
  rows = postmark_get("/message-streams/#{stream}/suppressions/dump")['Suppressions'].to_a
  total_suppressed += rows.size

  by_reason = rows.group_by { |r| r['SuppressionReason'] }
                  .map { |k, v| "#{k}:#{v.size}" }.sort.join(' ')
  puts "  #{stream}: #{rows.size} suppressed (#{by_reason})"

  rows.each do |row|
    email  = row['EmailAddress'].to_s.strip
    reason = row['SuppressionReason']
    next if email.empty?

    participants = Participant.where(email: email, no_email: false)
    if participants.empty?
      unmatched += 1 unless Participant.exists?(email: email)
      next
    end

    participants.each do |p|
      puts "    #{DRY_RUN ? 'would set' : 'setting'} no_email: participant #{p.id} " \
           "<#{email}> reason=#{reason}"
      next num_removed += 1 if DRY_RUN

      p.no_email = true
      p.no_email_reason = reason
      # Don't trust a bare save here. These are old records and this codebase has form
      # for latent validation failures on them; a silent `false` would leave the address
      # mailable and the problem would look fixed when it was not.
      if p.save
        num_removed += 1
      else
        failed += 1
        puts "      WARN participant #{p.id} did NOT save: #{p.errors.full_messages.join('; ')}"
      end
    end
  end
end

puts "#{total_suppressed} suppressed addresses seen, #{unmatched} matching no participant"
puts "#{failed} participant(s) FAILED to save" if failed.positive?
puts "#{num_removed} users #{DRY_RUN ? 'would be ' : ''}set to no_email"
