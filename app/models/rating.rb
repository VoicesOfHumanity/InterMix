class Rating < ActiveRecord::Base
  belongs_to :participant, optional: true
  belongs_to :remote_actor, optional: true
  belongs_to :item, optional: true
  belongs_to :group, optional: true
  belongs_to :period, optional: true
end
