require File.dirname(__FILE__)+'/cron_helper'


puts "Create communities from cities that have been selected *****************"

participants = Participant.where(status: 'active')
for p in participants
  next if p.city.to_s == '' or p.admin1uniq.to_s == ''
  
  puts "##{p.id} : #{p.email} : #{p.city}"
  
  geoname = Geoname.where(name: p.city, country_code: p.country_code, admin1_code: adminuniq_part(p.admin1uniq), fclasscode: 'P.PPL').first
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
      puts "  adding to community #{p.city_uniq}"
      p.tag_list.add(community.tagname)
    end
    p.save
  else
    puts "  not found"
  end

end



