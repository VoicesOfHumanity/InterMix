require File.dirname(__FILE__)+'/cron_helper'

puts "Create communities from religions that have been selected *****************"

conversation = Conversation.find_by_id(RELIGIONS_CONVERSATION_ID)

participants = Participant.where(status: 'active')
for p in participants
  for p_r in p.participant_religions
    next  if ! p_r.religion
    r = p_r.religion
    denomination = p_r.religion_denomination
    
    puts "##{p.id} : #{p.email} : #{r.name} - #{denomination}"    

    # Create/Join city community
    community = Community.where(context: 'religion', context_code: r.id).first
    if not community     
      tagname = r.shortname     
      puts "  creating religion community #{tagname}"
      community = Community.create(tagname: tagname, context: 'religion', context_code: r.id, fullname: r.name)
    end
    if community
      puts "  adding tag to user"
      p.tag_list.add(community.tagname)
      
      conversation_communities = ConversationCommunity.where(conversation_id: conversation.id, community_id: community.id)
      if conversation_communities.length > 1
        for cc in conversation_communities[1..100]
          puts "  getting rid of extra conversation_community"
          cc.destroy
        end
      elsif conversation_communities.length == 0
        puts "  adding community to conversation"
        conversation.communities << community
      end
    end
    p.save
    
  end

end  
