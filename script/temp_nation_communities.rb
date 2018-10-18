require File.dirname(__FILE__)+'/cron_helper'

# Item.tag_counts_on(:tags).collect{|t| t.name}
# Item.tags

puts "Communities from countries *****************"

countries = Geocountry.order(:name)

for country in countries
  
  community = Community.where(context: 'nation', context_code: country.iso3).first
  if not community
    shortname = country.name.gsub(' ','').downcase
    puts "creating #{shortname} for #{country.iso3}:#{country.name}"
    community = Community.create(tagname: shortname, context: 'nation', context_code: country.iso3, fullname: country.name)
  end

end





