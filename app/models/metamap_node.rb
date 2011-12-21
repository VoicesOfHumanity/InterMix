class MetamapNode < ActiveRecord::Base
  belongs_to :metamap
  has_many :metamap_node_participants
  has_many :participants, :through=>:metamap_node_participants
  
  def to_liquid
      {'id'=>id,'name'=>name,'description'=>description}
  end
  
end
