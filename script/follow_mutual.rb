# Make sure mutual followers (friends) are properly recorded

require File.dirname(__FILE__)+'/cron_helper'

numfollows = 0
nummutual = 0
numfixed = 0

follows = Follow.where("(following_id is not null and following_id>0) or (following_remote_actor_id is not null and following_remote_actor_id>0)")
numfollows = follows.length
puts "#{numfollows} follows"
for follow in follows
  if follow.following_remote_actor_id.to_i > 0 and follow.followed_id.to_i > 0
    # a remote person is following somebody local. Is the reverse true?
    puts "remote #{follow.following_remote_actor_id} following local {follow.followed_id}"
    reverse = Follow.where(following_id: follow.followed_id, followed_remote_actor_id: follow.following_remote_actor_id).first
  elsif follow.following_id.to_i > 0
    # a local person is following somebody local or remote
    if follow.followed_remote_actor_id.to_i > 0
      # following somebody remote. Is the reverse true?
      puts "local #{follow.following_id} following remote #{follow.followed_remote_actor_id}"
      reverse = Follow.where(following_remote_actor_id: follow.followed_remote_actor_id, followed_id: follow.following_id).first
    else
      # following somebody else local
      puts "local #{follow.following_id} following local #{follow.followed_id}"
      reverse = Follow.where(following_id: follow.followed_id, followed_id: follow.following_id).first      
    end
  end
  if reverse
    nummutual += 1
    if reverse.mutual and follow.mutual
      puts " - it is mutual. already set"
    else
      puts " - it is mutual. CORRECTING"
      if reverse.mutual === false
        reverse.mutual = true
        reverse.save!
      end
      if follow.mutual === false
        follow.mutual = true
        follow.save!
      end
      numfixed += 1
    end
  elsif follow.mutual
    puts " - it is NOT mutual. CORRECTING"
    follow.mutual = false
    follow.save!
    numfixed += 1    
  end
end

puts "#{numfollows} follows"
puts "#{nummutual} mutuals"
puts "#{numfixed} fixed"
