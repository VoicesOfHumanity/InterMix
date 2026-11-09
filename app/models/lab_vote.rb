# One answer shown to one voter in one round; `picked` if they chose it.
class LabVote < ApplicationRecord
  belongs_to :lab_question
  belongs_to :lab_answer
  belongs_to :participant, optional: true
end
