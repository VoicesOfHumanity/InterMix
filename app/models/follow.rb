class Follow < ActiveRecord::Base
  
  #belongs_to :followed, :class_name => 'Participant'
  #belongs_to :following, :class_name => 'Participant'
  
  belongs_to :follower, optional: true, :class_name => 'Participant', :foreign_key => :following_id
  belongs_to :idol, optional: true, :class_name => 'Participant', :foreign_key => :followed_id

  belongs_to :remote_follower, optional: true, class_name: 'RemoteActor', foreign_key: :following_remote_actor_id
  belongs_to :remote_idol, optional: true, class_name: 'RemoteActor', foreign_key: :followed_remote_actor_id

end
