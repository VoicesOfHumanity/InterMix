require File.dirname(__FILE__)+'/cron_helper'

# Capitalize nation community shortnames

fix = {
'ATG' => 'AntiguaBarbuda',
'BIH' => 'BosniaHerzgvna',
'IOT' => 'BritIndiaOcean',
'VGB' => 'BritVrginIsles',
'CAF' => 'CAR',
'CXR' => 'ChristmasIsland',
'COG' => 'CongoRepublic',
'DOM' => 'DominicanRepub',
'COD' => 'DRCongo',
'ANT' => 'DutchAntilles',
'GNQ' => 'EquatorGuinea',
'FLK' => 'FalklandIslands',
'PYF' => 'FrenchPolynesia',
'ATF' => 'FrenchSouthTer',
'HMD' => 'HeardMcDonald',
'MHL' => 'MarshallIsles',
'MNP' => 'NorthMarianas',
'PNG' => 'PapuaNewGuinea',
'SPM' => 'SaintPierre',
'VCT' => 'SaintVincent',
'STP' => 'SaoTome',
'SCG' => 'SerbiaMonte',
'SGS' => 'SGeorgiaIsles',
'SLB' => 'SolomonIslands',
'BLM' => 'StBarthelemy',
'KNA' => 'StKittsNevis',
'SJM' => 'SvalbardAndJan',
'TTO' => 'TrinidadTobago',
'TCA' => 'TurksAndCaicos',
'ARE' => 'UAEmirates',
'UMI' => 'USMinorIsles',
'VIR' => 'USVirginIsles',
'WLF' => 'WallisFutuna',
}

coms = Community.where(is_sub: false, context: 'nation')

for com in coms
  iso3 = com.context_code
  
  oldshort = com.tagname

  puts "#{com.tagname} : #{iso3} : #{com.fullname}"
    
  if fix.has_key?(iso3)
    newshort = fix[iso3]
    puts " -> manual: #{newshort}"
  else
    #orig_lower = com.fullname.gsub(' ','').downcase
    
    parts = com.fullname.split(' ')
    if parts.length > 1
      newshort = ''
      for part in parts
        newshort << part.capitalize
      end
      puts " -> composite: #{newshort}"
    else
      newshort = com.tagname.capitalize
      puts " -> simple: #{newshort}"
    end
  end
  
  tagrec = Tag.find_by_name(oldshort)
  if tagrec
    puts "    updating Tag"
    tagrec.name = newshort
    tagrec.save
  else
    puts "    CAN'T FIND TAG #{oldshort}"  
  end
  
  if com.tagname != newshort
    puts "    updating community"
    com.tagname = newshort
    com.save
  end
  
end