class Geoname < ApplicationRecord
  belongs_to :geocountry, :foreign_key=>:country_code, :primary_key=>:iso
  
end
