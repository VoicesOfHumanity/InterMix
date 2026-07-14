class MetamapNodeParticipant < ActiveRecord::Base
  belongs_to :metamap, optional: true
  belongs_to :metamap_node, optional: true
  belongs_to :participant, optional: true
end
