# Send back responses to some things that are automatic, like follow requests

require File.dirname(__FILE__)+'/cron_helper'

include ActivityPub

logger = @logger
logger.info("activitypub_responses")

requests = ApiRequest.where("request_body is not null").where("processed=0 or redo=1").order("id")
puts "#{requests.length} requests to process"

for req in requests
  puts "##{req.id} #{req.created_at}"

  obj = obj_from_request(req)
  puts " - object: #{obj}"
  if not obj
    puts " - no object"
    req.problem = true
    req.redo = false
    req.save
    next
  end

  data = get_request_data(obj)
  
  if data['status'] == 'error'
    puts " - error: #{data['error']}"
    req.problem = true
    req.redo = true
    req.save
    next
  end
  
  rtype = data['rtype']
  
  puts " - atype: #{data['atype']}"
  puts " - otype: #{data['otype']}"
  puts " - rtype: #{data['rtype']}"
  puts " - from_actor_url: #{data['from_actor_url']}"
  puts " - to_actor_url: #{data['to_actor_url']}"
  puts " - from_remote_actor: #{data['from_remote_actor'].account if data['from_remote_actor']}"
  puts " - to_participant: #{data['to_participant'].email if data['to_participant']}"

  next

  if rtype == '' or rtype == '?'
    req.problem = true
    req.redo = true
    req.save
    
  elsif rtype == 'note'
    # A note being sent to one of our users, hopefully a private message
    
    
  elsif rtype == 'follow_request'
    # Somebody wants to follow our user
    respond_to_follow

  elsif rtype == 'accept_follow'
    # Acceptance of a follow request from our user
    
  else
    req.problem = true
    req.redo = true
    req.save
  end

end