class Complaint < ApplicationRecord

  belongs_to :item
  belongs_to :poster, foreign_key: :poster_id, class_name: 'Participant'
  belongs_to :complainer, foreign_key: :complainer_id, class_name: 'Participant'

end
