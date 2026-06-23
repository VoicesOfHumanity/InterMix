# One-time (idempotent) triage of the ActivityPub inbox backlog.
#
# Background: the inbox records every incoming request into api_requests, but the
# processing cron (activitypub_responses) was not scheduled for years, so a large
# backlog of unprocessed requests accumulated (mostly very old). We do NOT want to
# replay years-old activities (follows/replies to long-dead threads, vanished
# accounts). This marks every unprocessed request older than a cutoff as processed
# + skipped, so the cron only ever handles recent traffic.
#
# Safe + reversible-in-spirit: it only flips status flags, never deletes rows.
# Idempotent: re-running it just re-affirms the same flags.
#
# Usage:
#   SYS_MODE=staging bundle exec rails runner script/activitypub_backlog_triage.rb
# Cutoff is configurable (days); default 30:
#   AP_BACKLOG_CUTOFF_DAYS=30 ... rails runner script/activitypub_backlog_triage.rb

require File.dirname(__FILE__)+'/cron_helper'

cutoff_days = (ENV['AP_BACKLOG_CUTOFF_DAYS'] || 30).to_i
cutoff = cutoff_days.days.ago

scope = ApiRequest.where("processed=0 or redo=1").where("created_at < ?", cutoff)

total_unprocessed = ApiRequest.where("processed=0 or redo=1").count
to_skip = scope.count

puts "ActivityPub backlog triage"
puts "  cutoff: #{cutoff_days} days (created before #{cutoff})"
puts "  currently unprocessed/redo: #{total_unprocessed}"
puts "  will mark skipped (older than cutoff): #{to_skip}"
puts "  will remain for the cron to process (newer than cutoff): #{total_unprocessed - to_skip}"

updated = scope.update_all(processed: true, problem: false, redo: false, updated_at: Time.now)

puts "Done. #{updated} requests marked processed/skipped."
puts "Remaining unprocessed/redo: #{ApiRequest.where("processed=0 or redo=1").count}"
