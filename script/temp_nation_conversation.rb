require File.dirname(__FILE__)+'/cron_helper'

# Add all nations to the international conversation, which should be INT_CONVERSATION_ID

communities = Community.where(context: 'nation')
for com in communities
  puts "#{com.id} : #{com.tagname} :#{com.fullname}"
  conversation_community = ConversationCommunity.where(conversation_id: INT_CONVERSATION_ID, community_id: com.id).first
  if conversation_community
    puts " - ok"
  else
    puts " - added"
    conversation_community = ConversationCommunity.create(conversation_id: INT_CONVERSATION_ID, community_id: com.id)
  end
end

