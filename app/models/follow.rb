class Follow < ActiveRecord::Base
  
  #belongs_to :followed, :class_name => 'Participant'
  #belongs_to :following, :class_name => 'Participant'
  
  belongs_to :follower, :class_name => 'Participant', :foreign_key => :following_id
  belongs_to :idol, :class_name => 'Participant', :foreign_key => :followed_id

  belongs_to :remote_follower, class_name: 'RemoteActor', foreign_key: :following_remote_actor_id
  belongs_to :remote_idol, class_name: 'RemoteActor', foreign_key: :followed_remote_actor_id

end
