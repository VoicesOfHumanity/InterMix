# Send back responses to some things that are automatic, like follow requests

require File.dirname(__FILE__)+'/cron_helper'

include ActivityPub

logger = @logger
logger.info("activitypub_responses")

requests = ApiRequest.where("request_body is not null").where("processed=0 or redo=1").order("id")
puts "#{requests.length} requests to process"

for req in requests
  puts "----------------------------------------------------------------------------\n"
  puts "##{req.id} #{req.created_at}"

  puts "getting object from request"
  obj = obj_from_request(req)
  if not obj
    puts " - no object"
    req.problem = true
    req.redo = false
    req.processed = true
    req.save
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
      puts "no problem, we don't know the actor, so nothing to delete"
      req.processed = true
      req.problem = false
      req.redo = false
    else
      req.processed = false
      req.problem = true
      req.redo = true
    end
    req.save
    next
  end

  puts "checking validity of signature and digest"
  if is_valid_request(req, data['from_remote_actor'], data['to_participant'])
    puts "this is a valid request"
  else
    puts "this is NOT a valid request"
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
    req.problem = true
    req.redo = true
    req.save
    
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
    # Our response didn't work, or we didn't know what to do
    puts "##{req.id} not processed. set to redo"
    req.problem = true
    req.redo = true
    req.save    
  end

  puts "----------------------------------------------------------------------------\n"

end

puts "#{requests.length} requests were processed"
