require File.dirname(__FILE__)+'/cron_helper'


puts "Create communities from cities that have been selected *****************"

conversation = Conversation.find_by_id(CITY_CONVERSATION_ID)

participants = Participant.where(status: 'active')
for p in participants
  next if p.city.to_s == '' or p.admin1uniq.to_s == ''
  
  puts "##{p.id} : #{p.email} : #{p.city}"
  
  geoname = Geoname.where(name: p.city, country_code: p.country_code, admin1_code: adminuniq_part(p.admin1uniq)).where("fclasscode like 'P.PPL%'").first
  if geoname
    p.city_uniq = "#{p.admin1uniq}_#{p.city}"
    # Create/Join city community
    community = Community.where(context: 'city', context_code: p.city_uniq).first
    if not community     
      tagname = p.city.gsub(/[^0-9A-za-z_]/i,'')     
      puts "  creating city community #{p.city_uniq} : #{tagname} : #{p.city}"
      community = Community.create(tagname: tagname, context: 'city', context_code: p.city_uniq, fullname: p.city)
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
  else
    puts "  not found"
  end

end



