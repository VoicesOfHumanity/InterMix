class MetamapNodeParticipant < ActiveRecord::Base
  belongs_to :metamap
  belongs_to :metamap_node
  belongs_to :participant
end
