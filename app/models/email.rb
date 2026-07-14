class Email < ApplicationRecord
  belongs_to :participant, optional: true
end
