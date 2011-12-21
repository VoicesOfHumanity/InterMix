class Follow < ActiveRecord::Base
  
  #belongs_to :followed, :class_name => 'Participant'
  #belongs_to :following, :class_name => 'Participant'
  
  belongs_to :follower, :class_name => 'Participant', :foreign_key => :following_id
  belongs_to :idol, :class_name => 'Participant', :foreign_key => :followed_id

end
