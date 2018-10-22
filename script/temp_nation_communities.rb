require File.dirname(__FILE__)+'/cron_helper'

# Item.tag_counts_on(:tags).collect{|t| t.name}
# Item.tags

puts "Create communities from countries *****************"

countries = Geocountry.order(:name)

for country in countries
  
  community = Community.where(context: 'nation', context_code: country.iso3).first
  if not community
    shortname = country.name.gsub(' ','').downcase
    puts "creating #{shortname} for #{country.iso3}:#{country.name}"
    community = Community.create(tagname: shortname, context: 'nation', context_code: country.iso3, fullname: country.name)
  end

end

puts "Add people to country communities based on country of residence *****************"

participants = Participant.where(status: 'active')
for p in participants
  country = nil
  if p.country_code and p.country_code.to_s != ''
    country = Geocountry.where(iso: p.country_code).first
  end
  if not country and p.country_name and p.country_name.to_s != ''
    country = Geocountry.where(name: p.country_name).first
  end
  if country
    community = Community.where(context: 'nation', context_code: country.iso3).first
    if community
      puts "#{p.email} in community #{community.tagname}"
      #p.tag_list.add(community.tagname)
      #p.save
    end
  end

end

puts "Add people to country communities based on UN Country of Origin *****************"

participants = Participant.where(status: 'active')
for p in participants
  country = nil
  
  mp = MetamapNodeParticipant.where(metamap_id: 4, participant_id: p.id).first
  if mp
    m = MetamapNode.where(metamap_id: 4, id: mp.metamap_node_id).first
    if m
      if not country and m.name and m.name.to_s != ''
        country = Geocountry.where(name: m.name).first
      end
    end
  end

  if country
    community = Community.where(context: 'nation', context_code: country.iso3).first
    if community
      puts "#{p.email} in community #{community.tagname}"
      #p.tag_list.add(community.tagname)
      #p.save
    end
  end

end


