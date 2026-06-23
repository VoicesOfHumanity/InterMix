# Send back responses to some things that are automatic, like follow requests

require_relative 'cron_helper'

include ActivityPub

logger = @logger
logger.info("activitypub_responses")

# Process a bounded batch per run. Loading the entire (historically 170k+) backlog
# into memory at once was both slow and memory-hungry.
BATCH_LIMIT = (ENV['AP_RESPONSES_LIMIT'] || 200).to_i
# After this many failed attempts, give up on a request instead of retrying it
# forever. Permanently-failing requests previously kept processed=0 and were
# re-selected every run, so the backlog could only grow.
MAX_TRIES = (ENV['AP_RESPONSES_MAX_TRIES'] || 5).to_i

requests = ApiRequest.where("request_body is not null").where("processed=0 or redo=1").order("id").limit(BATCH_LIMIT)
puts "#{requests.length} requests to process (limit #{BATCH_LIMIT})"

# Mark a request as permanently given up on (will not be re-selected).
give_up = lambda do |req, reason|
  puts "##{req.id} giving up: #{reason}"
  req.processed = true
  req.problem = true
  req.redo = false
  req.save
end

# Record a failed attempt; retry later unless we've hit the cap, then give up.
fail_attempt = lambda do |req, reason|
  req.tries = req.tries.to_i + 1
  if req.tries >= MAX_TRIES
    give_up.call(req, "#{reason} (after #{req.tries} tries)")
  else
    puts "##{req.id} will retry (#{reason}); tries=#{req.tries}"
    req.problem = true
    req.redo = true
    req.processed = false
    req.save
  end
end

for req in requests
  begin
    puts "----------------------------------------------------------------------------\n"
    puts "##{req.id} #{req.created_at} (tries=#{req.tries})"

    puts "getting object from request"
    obj = obj_from_request(req)
    if not obj
      # No parseable body: this will never succeed, so give up terminally.
      give_up.call(req, "no object in request body")
      next
    end
    puts " - object: #{obj}"

    puts "getting request data from object"
    data = get_request_data(obj)

    rtype = data['rtype']

    puts " - atype: #{data['atype']}"
    puts " - otype: #{data['otype']}"
    puts " - rtype: #{data['rtype']}"
    puts " - from_actor_url: #{data['from_actor_url']}"
    puts " - to_actor_url: #{data['to_actor_url']}"
    puts " - from_remote_actor: #{data['from_remote_actor'].account if data['from_remote_actor']}"
    puts " - to_participant: #{data['to_participant'].email if data['to_participant']}"
    puts " - ref_id: #{data['ref_id']}"
    puts " - replying_to: #{data['replying_to']}"
    puts " - content: #{data['content']}"
    puts " - attachment: #{data['attachment']}"
    puts " - date: #{data['date']}"

    if data['status'] == 'error'
      puts " - error: #{data['error']}"
      if rtype == 'delete_actor'
        # We don't know the actor, so there's nothing to delete. That's fine.
        puts "no problem, we don't know the actor, so nothing to delete"
        req.processed = true
        req.problem = false
        req.redo = false
        req.save
      else
        fail_attempt.call(req, "error getting request data: #{data['error']}")
      end
      next
    end

    puts "checking validity of signature and digest"
    if is_valid_request(req, data['from_remote_actor'], data['to_participant'])
      puts "this is a valid request"
    else
      # Previously this did a bare `next`, leaving processed=0 so the request was
      # retried on every run forever. Cap the retries instead.
      puts "this is NOT a valid request"
      fail_attempt.call(req, "invalid signature/digest")
      next
    end

    from_remote_actor = data['from_remote_actor']
    to_participant = data['to_participant']
    ref_id = data['ref_id']
    replying_to = data['replying_to']
    content = data['content']
    attachment = data['attachment']
    date = data['date']
    object = data['object']

    res = nil

    if rtype == '' or rtype == '?'
      # Unknown activity type — deterministic, won't fix itself. Give up.
      give_up.call(req, "unknown rtype")
      next

    elsif rtype == 'post'
      # A public post
      puts "processing a public post"
      res = respond_to_post(from_remote_actor, ref_id, req.id, content, date, object, ref_id, replying_to, attachment)

    elsif rtype == 'note'
      # A note being sent to one of our users, hopefully a private message
      puts "processing a received personal note"
      res = respond_to_note(from_remote_actor, to_participant, ref_id, req.id, content, date, object, ref_id, replying_to)

    elsif rtype == 'follow_request'
      # Somebody wants to follow our user
      puts "processing a received follow request"
      res = respond_to_follow(from_remote_actor, to_participant, ref_id, req.id)

    elsif rtype == 'accept_follow'
      # Acceptance of a follow request from our user
      puts "processing accept of our follow request"
      res = respond_to_accept_follow(from_remote_actor, to_participant, ref_id, req.id)

    elsif rtype == 'delete_actor'
      # A remote account has been removed. We should remove it from follows
      puts "processing a delete_actor event"
      res = respond_to_delete_actor(from_remote_actor)

    elsif rtype == 'like'
      # A like of one of our posts. To convert into a vote
      puts "processing a like event from #{from_remote_actor.id}"
      res = respond_to_like(from_remote_actor, ref_id)

    end

    if res
      # Our response was carried out
      puts "##{req.id} succesfully processed"
      req.our_function = rtype
      req.processed = true
      req.redo = false
      req.problem = false
      req.save
    else
      # Our response didn't work — retry up to the cap, then give up.
      fail_attempt.call(req, "handler for #{rtype} returned false")
    end

    puts "----------------------------------------------------------------------------\n"

  rescue => e
    # Never let one bad request abort the batch.
    puts "##{req.id} ERROR: #{e.class}: #{e}"
    logger.info("activitypub_responses error on request ##{req.id}: #{e.class}: #{e}")
    begin
      fail_attempt.call(req, "exception: #{e.class}")
    rescue => e2
      logger.info("activitypub_responses could not record failure for ##{req.id}: #{e2}")
    end
  end
end

puts "#{requests.length} requests were processed"
