# This is just to allow some things that were in the items controller to be available in other places, like activitypub

module ItemLib
  
  def rateitem(item, vote, from_mail=false, conversation_id=0, remote_actor=nil)
    # Called by fx thumbrate or view to record a vote, without showing any screen
    
    # A thumb vote is recorded as approval, -3 ... +3
    # The absolute value is stored as interest, which otherwise has a 1-5 range
    # A thumb vote from mail can only be -1 or +1
    # If one has commented on the item, set the interest to 4
    # If Important Issue is checked, we add 1 to the interest
    # If unchecked, remove that 1 again
    
    Rails.logger.info("items#rateitem vote:#{vote} #{remote_actor ? "remote" : "local"}")
    #puts "items#rateitem vote:#{vote} #{remote_actor ? "remote" : "local"}"
  
    begin
      participant = current_participant
    rescue
      participant = nil
    end
    if not participant and not remote_actor
      Rails.logger.info("items#rateitem items#rateitem no voter")
      return
    end
    if not item
      return
    end
    if participant and not item.voting_ok(participant.id)
      Rails.logger.info("items#rateitem voting is not ok")
      return
    end  
  
    item_id = item.id
    group_id = item.group_id.to_i
    dialog_id = item.dialog_id.to_i
    is_new = false
  
    # check for comments in that thread
    #com_count = Item.where(posted_by: current_participant.id, is_first_in_thread: false, first_in_thread: item.first_in_thread).count
    # check for comments on that message
    com_count = 0
    if participant
      com_count = Item.where(posted_by: participant.id, reply_to: item_id).count
    elsif remote_actor
      com_count = Item.where(posted_by_remote_actor_id: remote_actor.id, reply_to: item_id).count
    end
  
    #-- See if that user already has rated that item, or create a new rating if they haven't
    if participant
      rating = Rating.where(item_id: item_id, participant_id: participant.id, rating_type: 'AllRatings').first
      if not rating
        is_new = true
        rating = Rating.create(item_id: item_id, participant_id: participant.id, rating_type: 'AllRatings', approval: vote, interest: vote.abs, importance: 0)
      end
    elsif remote_actor
      puts "items#rateitem remote vote"
      rating = Rating.where(item_id: item_id, remote_actor_id: remote_actor.id, rating_type: 'AllRatings').first
      if not rating
        is_new = true
        rating = Rating.create(item_id: item_id, remote_actor_id: remote_actor.id, rating_type: 'AllRatings', approval: vote, interest: vote.abs, importance: 0)
      end
    end

    Rails.logger.info("items#rateitem rating:#{rating ? rating.id : "none"}")
    #puts "items#rateitem rating:#{rating ? rating.id : "none"}"
  
    if conversation_id.to_i == 0
      conversation_id = item.conversation_id
    end
    if conversation_id.to_i > 0
      conversation = Conversation.find_by_id(conversation_id)
      if conversation and participant and conversation.is_member_of(participant)
        # In a conversation in together mode, the vote is valid if the user is a member of any community that is in the conversation
        # If we're in apart mode, it is only valid if they're in the same community as the poster
        if conversation.together_apart == 'apart'
          if item.representing_com.to_s != '' and participant.tag_list_downcase.include?(item.representing_com.downcase)
            rating.conversation_id = conversation_id          
          end
        else
          rating.conversation_id = conversation_id          
        end
      end
    end
  
    if is_new
      # We just saved the initial rating
    elsif rating and from_mail
      #-- If it was from an email, there's only -1 and +1 choice. If we already had a rating, only do something if it changed direction
      # https://intermix.test:3002/items/2111/view?auth_token=Y8fCCBYWx8-ETHcyWGC4&thumb=-1
      if rating.approval and rating.approval.to_i > 0 and vote < 0
        rating.approval = vote    
        rating.interest = vote.abs
      elsif rating.approval and rating.approval.to_i < 0 and vote > 0
        rating.approval = vote    
        rating.interest = vote.abs
      elsif rating.approval
        return       
      end
    elsif rating.approval == vote and participant
      #-- If they clicked on the existing rating, turn it off
      rating.approval = 0    
      rating.interest = 0
    else
      rating.approval = vote    
      rating.interest = vote.abs
    end
  
    if com_count > 0
      rating.interest = 4
    end
    if rating.importance.to_i > 0
      rating.interest += 1
    end
    rating.save!
  
    item_rating_summary = ItemRatingSummary.where(item_id: item_id).first_or_create

    item_rating_summary.recalculate(false,item.dialog)
    if (dialog_id > 0 and rating.dialog_id.to_i == 0) or (group_id > 0 and rating.group_id.to_i == 0)
      rating.group_id = group_id
      rating.dialog_id = dialog_id
      if dialog_id > 0
        dialog = Dialog.find_by_id(dialog_id)
        rating.period_id = dialog.current_period if dialog
      end
      rating.save
    end
  
    item.approval = item_rating_summary.app_average
    item.interest = item_rating_summary.int_average
    item.value = item_rating_summary.value
    item.controversy = item_rating_summary.controversy
    item.edit_locked = true if participant and participant.id != item.posted_by
    item.save
    
    return rating.id
  end
  
end