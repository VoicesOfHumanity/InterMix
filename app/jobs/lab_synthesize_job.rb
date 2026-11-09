# Drafts an AI common-ground answer for a /lab/agree question, off the request path.
class LabSynthesizeJob < ActiveJob::Base
  def perform(question_id)
    question = LabQuestion.find_by(id: question_id)
    return unless question
    answer = Lab::Ai.draft_common_ground(question)
    Rails.logger.info("LabSynthesizeJob q=#{question_id} drafted=#{answer&.id.inspect}")
  end
end
