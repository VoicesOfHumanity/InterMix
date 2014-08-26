class Period < ActiveRecord::Base
  belongs_to :group
  belongs_to :dialog
  has_many :items
  
  serialize :result
  
  def to_liquid
      {'id'=>id,'name'=>name,'shortname'=>shortname,'description'=>description,'shortdesc'=>shortdesc,'instructions'=>instructions,'max_messages'=>max_messages,'startdate'=>startdate,'endposting'=>endposting,'endrating'=>endrating,'result'=>result}
  end
  
  def previous_period
    #-- Return the previous period, if there was one, based on numbering
    pp = nil
    if self.period_number.to_i > 1
      pp = Period.where(:dialog_id=>self.dialog.id).where(:period_number=>(self.period_number-1)).first
    end  
    pp  
  end  
  
end
