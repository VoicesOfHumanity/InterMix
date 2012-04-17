class Period < ActiveRecord::Base
  belongs_to :group
  belongs_to :dialog
  has_many :items
end
