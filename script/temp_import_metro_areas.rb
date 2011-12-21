# encoding: utf-8

# Import metropolitan areas from csv file
# From http://www.populationdata.net/index2.php?lang=EN&option=palmares&rid=4&nom=grandes-villes
# copy html and special paste unicode to excel, remove a column, save as csv.
#1;Tokyo;37 730 064 (2010);Japan
#2;New York;25 933 312 (2011);United States
#3;Mexico;23 293 783 (2010);Mexico

require File.dirname(__FILE__)+'/cron_helper'

#IO.foreach("/Users/ffunch/Documents/metropolitan.csv") do |line|
IO.foreach("/tmp/metropolitan.csv") do |line|
  line = line.strip
  xarr = line.split(';')
  metro = xarr[1]
  xpopulation = xarr[2]
  country_name = xarr[3]
  
  r = xpopulation.match(/([^(]+)\(([0-9]+)\)/)
  population = r[1].gsub(' ','').to_i
  population_year = r[2].to_i
  
  case country_name
  when "Côte d'Ivoire"
    country_code = 'CI'
  when "Congo"
    country_code = 'CD'
  when "Burma (Myanmar)"
    country_code = 'MM'
  when "Palestine"
    country_code = 'PS'
  when "Guinée"    
    country_code = 'GN'
  else
    country = Geocountry.find_by_name(country_name)
    if country
      country_code = country.iso
    else  
      puts "  couldn't find #{country_name}"
      country_code = '??'
    end      
  end

  puts "area:#{metro} - pop:#{population} year:#{population_year} - #{country_code}:#{country_name}"

  MetroArea.create(:name=>metro, :country_code=>country_code, :population=>population, :population_year=>population_year)


end


