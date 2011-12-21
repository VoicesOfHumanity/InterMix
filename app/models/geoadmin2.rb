class Geoadmin2 < ActiveRecord::Base
  belongs_to :geocountry, :foreign_key=>:country_code, :primary_key=>:country_code
  belongs_to :geoadmin1, :foreign_key=>:admin1uniq, :primary_key=>:admin1uniq

  def self.findornot(id)
    id = id.to_i
    return nil if id<=0
    begin
      rec = find(id)
    rescue
    end  
    if rec
      return rec
    else
      return nil
    end        
  end  

end
