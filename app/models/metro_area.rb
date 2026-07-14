class MetroArea < ActiveRecord::Base
  belongs_to :geocountry, optional: true, :foreign_key=>:country_code, :primary_key=>:iso
  
  def to_liquid
      {'id'=>id,'name'=>name}
  end
  
end
