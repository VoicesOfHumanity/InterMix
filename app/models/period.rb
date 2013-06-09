class Period < ActiveRecord::Base
  belongs_to :group
  belongs_to :dialog
  has_many :items
  
  def to_liquid
      {'id'=>id,'name'=>name,'shortname'=>shortname,'description'=>description,'shortdesc'=>shortdesc,'instructions'=>instructions,'max_messages'=>max_messages,'startdate'=>startdate,'endposting'=>endposting,'endrating'=>endrating}
  end
  
end
