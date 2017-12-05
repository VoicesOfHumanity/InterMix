class Community < ActiveRecord::Base
  
  attr_accessor :members
  attr_accessor :activity
  
  def member_count
    Participant.tagged_with(self.tagname).count
  end
  
  def activity_count
    #-- Count the number of messages in the past month    
    Item.where("intra_com='@#{self.tagname}'").where('created_at > ?', 31.days.ago).count
  end
  
  def geo_counts
    members = Participant.tagged_with(self.tagname)
    nations = {}
    states = {}
    metros = {}
    cities = {}
    for member in members
      metros[member.metro_area_id] = true if member.metro_area_id.to_i > 0
      nations[member.country_code] = true if member.country_code.to_s != ''
      states[member.admin1uniq] = true if member.admin1uniq.to_s != ''
      cities[member.city.downcase] = true if member.city.to_s != ''      
    end
    return {nations: nations.length, states: states.length, metros: metros.length, cities: cities.length}
  end
  
end
