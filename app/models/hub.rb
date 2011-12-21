class Hub < ActiveRecord::Base
  has_many :hub_admins
  has_many :participants, :through => :hub_admins
end
