class Geoname < ApplicationRecord
  belongs_to :geocountry, optional: true, :foreign_key=>:country_code, :primary_key=>:iso
  
end
