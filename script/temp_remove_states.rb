# remove admin1s (states) that have no cities, to make the city selection make more sense

require File.dirname(__FILE__)+'/cron_helper'

admin1s = Geoadmin1.order("country_code,name")

keep = 0
remove = 0

for admin1 in admin1s do
  country_code = admin1.country_code
  admin1_code = admin1.admin1_code
  cities = Geoname.where(country_code: country_code, admin1_code: admin1_code, fclasscode: 'P.PPL')
  if cities.length == 0
    remove += 1
    puts "#{country_code}:#{admin1_code}:#{admin1.name} REMOVE"
    admin1.destroy
  else
    keep += 1
    puts "#{country_code}:#{admin1_code}:#{admin1.name} keep"
  end  
end

puts "#{admin1s.length} states processed"
puts "#{remove} removed"
puts "#{keep} kept"