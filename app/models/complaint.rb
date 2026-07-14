class Complaint < ApplicationRecord

  belongs_to :item, optional: true
  belongs_to :poster, optional: true, foreign_key: :poster_id, class_name: 'Participant'
  belongs_to :complainer, optional: true, foreign_key: :complainer_id, class_name: 'Participant'

end
