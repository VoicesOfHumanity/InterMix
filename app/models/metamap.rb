class Metamap < ActiveRecord::Base
  has_many :metamap_nodes
  
  has_many :dialog_metamaps
  has_many :dialogs, :through => :dialog_metamaps
  
  has_many :metamap_node_participants
  has_many :participants, :through=>:metamap_node_participants
  
  def to_liquid
      {'id'=>id,'name'=>name}
  end
  
end
