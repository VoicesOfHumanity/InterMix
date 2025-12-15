class Block < ActiveRecord::Base
  belongs_to :blocker, class_name: 'Participant'
  belongs_to :blocked, class_name: 'Participant'

  validates :blocker_id, presence: true
  validates :blocked_id, presence: true
  validates :blocked_id, uniqueness: { scope: :blocker_id }
end


