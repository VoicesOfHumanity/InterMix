class Rating < ActiveRecord::Base
  belongs_to :participant, optional: true
  belongs_to :remote_actor, optional: true
  belongs_to :item
  belongs_to :group
  belongs_to :period
end
