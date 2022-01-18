require File.dirname(__FILE__)+'/cron_helper'

puts "Create communities for all genders and generations *****************"

conversation = Conversation.find_by_id(GENDER_CONVERSATION_ID)

genders = {
	208 => {
		'name' => 'female',
		'plural' => 'Women',
		'group' => 'Voice of Women',
		'tag' => 'VoiceofWomen'
	},
	207 => {
		'name' => 'male',
		'plural' => 'Men',
		'group' => 'Voice of Men',
		'tag' => 'VoiceofMen'
	}
}
#408 => {
#	'name' => 'simply-human',
#	'plural' => 'Simply Human',
#	'group' => 'Voice of Humanity',
#	'tag' => 'VoiceOfHumanity'
#}

genders.each do |code,info|
  puts "#{code}:#{info['group']}"
	community = Community.where(context: 'gender', context_code: code).first
	if not community
    puts " - creating community"
		tagname = info['tag']
		group = info['group']
		community = Community.create(fullname: group, tagname: tagname, context: 'gender', context_code: code)
	end
  concom = ConversationCommunity.where(conversation_id: conversation.id, community_id: community.id).first
  if not concom
    puts " - adding to conversation"
    concom = ConversationCommunity.create(conversation_id: conversation.id, community_id: community.id)
  end
end

conversation = Conversation.find_by_id(GENERATION_CONVERSATION_ID)

generations = {
	405 => {
		'name' => 'young',
		'plural' => 'Youth',
		'group' => 'Voice of Youth',
		'tag' => 'VoiceOfYouth'
	},
	406 => {
		'name' => 'middle-aged',
		'plural' => '',
		'group' => 'Voice of Experience',
		'tag' => 'VoiceOfExperience'
	},
	407 => {
		'name' => 'senior',
		'plural' => '',
		'group' => 'Voice of Wisdom',
		'tag' => 'VoiceOfWisdom'
	}
}
#409 => {
#	'name' => 'simply-human',
#	'plural' => 'Simply Human',
#	'group' => 'Voice of Humanity',
#	'tag' => ''
#}

generations.each do |code,info|
  puts "#{code}:#{info['group']}"
  community = Community.where(context: 'generation', context_code: code).first
	if not community
    puts " - creating community"
		tagname = info['tag']
		group = info['group']
		community = Community.create(fullname: group, tagname: tagname, context: 'generation', context_code: code)
	end
  concom = ConversationCommunity.where(conversation_id: conversation.id, community_id: community.id).first
  if not concom
    puts " - adding to conversation"
    concom = ConversationCommunity.create(conversation_id: conversation.id, community_id: community.id)
  end
end
