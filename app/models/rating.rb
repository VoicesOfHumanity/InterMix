class Rating < ActiveRecord::Base
  belongs_to :participant
  belongs_to :item
  belongs_to :group
end
