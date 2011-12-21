class GroupSubtag < ActiveRecord::Base
  belongs_to :group
  has_many :group_subtag_participants
  has_many :participants, :through => :group_subtag_participants
end
