class Religion < ApplicationRecord
  has_many :participant_religions
  has_many :participants, :through => :participant_religions

  def self.custom_order
    ret = "CASE"
    ret << " WHEN name = 'Other' THEN 'XXXX'"
    ret << " ELSE name"
    ret << " END"
  end
  
  # custom_order is a hardcoded CASE expression (no user input); Rails 6.1+
  # requires raw SQL passed to order() to be wrapped in Arel.sql().
  scope :order_by_custom, -> { order(Arel.sql(custom_order)) }
  
end
