class Religion < ApplicationRecord
  has_many :participant_religions
  has_many :participants, :through => :participant_religions

  def self.custom_order
    ret = "CASE"
    ret << " WHEN name = 'Other' THEN 'XXXX'"
    ret << " ELSE name"
    ret << " END"
  end
  
  #scope :order_by_custom, -> { order(custom_order) }
  scope :order_by_custom, -> { order(Arel.sql(custom_order).asc) }
  
  #scope :order_by_start_date_asc, -> { order(Arel.sql("lms_data->>'startDate'").asc) }


end
