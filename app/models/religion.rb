class Religion < ApplicationRecord
  has_many :participant_religions
  has_many :participants, :through => :participant_religions

end
