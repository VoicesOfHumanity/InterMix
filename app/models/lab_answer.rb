class LabAnswer < ApplicationRecord
  MAX_LENGTH = 200

  belongs_to :lab_question
  belongs_to :participant, optional: true
  has_many :lab_votes, dependent: :delete_all

  validates :body, presence: true, length: { minimum: 3, maximum: MAX_LENGTH }
  validates :author_kind, inclusion: { in: %w[person ai demo] }

  scope :live, -> { where(status: 'active') }

  def ai?
    author_kind == 'ai'
  end

  def source_ids
    source_answer_ids.to_s.split(',').map(&:to_i)
  end
end
