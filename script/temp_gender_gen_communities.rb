require File.dirname(__FILE__)+'/cron_helper'

puts "Create communities for all genders and generations *****************"

conversation = Conversation.find_by_id(GENDER_CONVERSATION_ID)

genders = {
	208 => {
		'name' => 'female',
		'plural' => 'Women',
		'group' => 'Voice of Women',
		'tag' => 'VoiceofWomen',
    'community' => nil
	},
	207 => {
		'name' => 'male',
		'plural' => 'Men',
		'group' => 'Voice of Men',
		'tag' => 'VoiceofMen',
    'community' => nil
	},
  408 => {
  	'name' => 'simply-human',
  	'plural' => 'Simply Human',
  	'group' => 'Gender Simply Human',
  	'tag' => 'gendersimplyhuman',
    'community' => nil
  }
}


genders.each do |code,info|
  puts "#{code}:#{info['group']}"
	community = Community.where(context: 'gender', context_code: code).first
	tagname = info['tag']
	group = info['group']
	if not community
    puts " - creating community"
		community = Community.create(fullname: group, tagname: tagname, context: 'gender', context_code: code)
	end
  community.fullname = group
  community.tagname = tagname
  community.save
  genders[code]['community'] = community
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
		'tag' => 'VoiceOfYouth',
    'community' => nil  
	},
	406 => {
		'name' => 'middle-aged',
		'plural' => '',
		'group' => 'Voice of Experience',
		'tag' => 'VoiceOfExperience',
    'community' => nil
	},
	407 => {
		'name' => 'senior',
		'plural' => '',
		'group' => 'Voice of Wisdom',
		'tag' => 'VoiceOfWisdom',
    'community' => nil
	},
  409 => {
  	'name' => 'simply-human',
  	'plural' => 'Simply Human',
  	'group' => 'Age Simply Human',
  	'tag' => 'agesimplyhuman',
    'community' => nil
  }
}


generations.each do |code,info|
  puts "#{code}:#{info['group']}"
  community = Community.where(context: 'generation', context_code: code).first
	tagname = info['tag']
	group = info['group']
	if not community
    puts " - creating community"
		community = Community.create(fullname: group, tagname: tagname, context: 'generation', context_code: code)
	end
  community.fullname = group
  community.tagname = tagname
  community.save
  generations[code]['community'] = community
  concom = ConversationCommunity.where(conversation_id: conversation.id, community_id: community.id).first
  if not concom
    puts " - adding to conversation"
    concom = ConversationCommunity.create(conversation_id: conversation.id, community_id: community.id)
  end
end

puts "participants"
participants = Participant.where(status: 'active')
for p in participants
  if p.tag_list.include?("VoiceOfHumanity")
    p.tag_list.remove("VoiceOfHumanity")
    p.save!
  end
  if p.gender_id > 0
    com = genders[p.gender_id]['community']
    if com
      if not p.tag_list_downcase.include?(com.tagname.downcase)
        p.tag_list.add(com.tagname)
        p.save!
        puts " - #{p.id}: gender:#{p.gender_id}:#{com.tagname}" 
      end
    end
  end
  if p.generation_id > 0
    com = generations[p.generation_id]['community']
    if com
      com.tagname
      if not p.tag_list_downcase.include?(com.tagname.downcase)
        p.tag_list.add(com.tagname)
        p.save!
        puts " - #{p.id}: generation:#{p.generation_id}:#{com.tagname}" 
      end
    end
  end
end
