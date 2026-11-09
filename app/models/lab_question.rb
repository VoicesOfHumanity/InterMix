# A question in the /lab/agree experiment. See db/migrate/20261109120000_create_lab_tables.rb
class LabQuestion < ApplicationRecord
  has_many :lab_answers, dependent: :delete_all
  has_many :lab_votes, dependent: :delete_all

  validates :title, presence: true, length: { maximum: 255 }

  scope :active, -> { where(active: true).order(:position, :id) }

  def live_answers
    lab_answers.where(status: 'active')
  end

  def human_answer_count
    lab_answers.where(author_kind: %w[person demo]).count
  end

  # Simulated demo voters (lab:demo_seed) carry negative participant ids
  def participant_count
    lab_votes.distinct.count(:participant_id)
  end

  # Claim the next AI drafting slot atomically, so two concurrent answer posts
  # cannot both enqueue a draft. Returns true if this caller should draft.
  def claim_synthesis!
    count = human_answer_count
    return false if count - answers_at_last_synth < synth_every
    LabQuestion.where(id: id, answers_at_last_synth: answers_at_last_synth)
               .update_all(answers_at_last_synth: count) == 1
  end
end
