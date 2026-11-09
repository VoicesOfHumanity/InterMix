# The /lab/agree experiment: pick-two flow, tallies, the cross-group score, and the
# AI hooks (with a fake provider - no network).
# NOTE: participants are MyISAM-era tables that do not roll back; clean up explicitly.
require 'rails_helper'

RSpec.describe '/lab/agree', type: :request do
  let!(:cleanup) { [] }
  let!(:question) { LabQuestion.create!(title: "Test question #{rand(1e9).to_i}", synth_every: 3) }
  let!(:answers) do
    %w[Alpha Bravo Charlie Delta Echo Foxtrot].map do |w|
      question.lab_answers.create!(body: "#{w} answer", author_kind: 'demo')
    end
  end
  let!(:participant) do
    p = Participant.new(email: "lab#{rand(1e9).to_i}@example.com",
                        password: 'testtest', password_confirmation: 'testtest')
    p.save!
    p.update_columns(status: 'active', confirmed_at: Time.now)
    MetamapNodeParticipant.create!(participant_id: p.id, metamap_id: 3, metamap_node_id: 208)
    MetamapNodeParticipant.create!(participant_id: p.id, metamap_id: 5, metamap_node_id: 405)
    cleanup << p
    p
  end

  after do
    Warden.test_reset!
    Lab::Ai.provider = nil
    MetamapNodeParticipant.where(participant_id: participant.id).delete_all
    question.destroy
    cleanup.each { |r| r.destroy rescue nil }
  end

  def vote(n, picks:, gender: nil, generation: nil, region: nil)
    n.times do
      token = SecureRandom.hex(12)
      answers.first(5).each do |a|
        LabVote.create!(lab_question: question, lab_answer: a, participant_id: -rand(1e6).to_i, demo: true,
                        round_token: token, picked: picks.include?(a.body),
                        gender_id: gender, generation_id: generation, region: region)
      end
    end
  end

  describe 'without signing in' do
    it 'shows the question list, a teaser and public results' do
      get '/lab/agree'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(question.title)

      get "/lab/agree/#{question.id}"
      expect(response.body).to include('Sign in to take part')

      get "/lab/agree/#{question.id}/results"
      expect(response).to have_http_status(:ok)
    end

    it 'cannot vote' do
      post "/lab/agree/#{question.id}/pick", params: { token: 'x', picked: [answers[0].id] }
      expect(response).to redirect_to("/lab/agree/#{question.id}")
      expect(LabVote.where(lab_question_id: question.id).count).to eq(0)
    end
  end

  describe 'signed in' do
    before { login_as(participant, scope: :participant) }

    it 'shows five answers and records the round with the voter profile' do
      get "/lab/agree/#{question.id}"
      expect(response).to have_http_status(:ok)
      shown = session[:lab_round]['ids']
      expect(shown.size).to eq(5)

      post "/lab/agree/#{question.id}/pick", params: { token: session[:lab_round]['token'], picked: shown.first(2) }
      expect(response).to redirect_to("/lab/agree/#{question.id}/results")

      votes = LabVote.where(lab_question_id: question.id, participant_id: participant.id)
      expect(votes.count).to eq(5)
      expect(votes.where(picked: true).pluck(:lab_answer_id)).to match_array(shown.first(2))
      expect(votes.pluck(:gender_id).uniq).to eq([208])
      expect(votes.pluck(:generation_id).uniq).to eq([405])

      follow_redirect!
      expect(response.body).to include('Your picks')
      expect(response.body).to include('of Women')
    end

    it 'ignores answers that were not shown, a third pick, and stale tokens' do
      get "/lab/agree/#{question.id}"
      round = session[:lab_round]
      hidden = (answers.map(&:id) - round['ids']).first
      post "/lab/agree/#{question.id}/pick", params: { token: round['token'], picked: [hidden] }
      expect(LabVote.where(lab_question_id: question.id).count).to eq(0)

      get "/lab/agree/#{question.id}"
      round = session[:lab_round]
      post "/lab/agree/#{question.id}/pick", params: { token: round['token'], picked: round['ids'].first(3) }
      expect(LabVote.where(lab_question_id: question.id).count).to eq(0)

      post "/lab/agree/#{question.id}/pick", params: { token: 'stale', picked: round['ids'].first(1) }
      expect(LabVote.where(lab_question_id: question.id).count).to eq(0)
    end

    it 'adds an answer with the author profile, never shows it back to its author' do
      post "/lab/agree/#{question.id}/answers", params: { body: 'My own answer' }
      mine = question.lab_answers.find_by(body: 'My own answer')
      expect(mine.participant_id).to eq(participant.id)
      expect(mine.gender_id).to eq(208)
      20.times do
        expect(Lab::Picker.new(question, participant).pick.map(&:id)).not_to include(mine.id)
      end
    end

    it 'offers the existing answer when the AI calls it a duplicate, and keeps it if insisted' do
      fake = Object.new
      def fake.json(**) = { 'duplicate_of_id' => LabAnswer.find_by(body: 'Alpha answer').id, 'reason' => 'Same idea.' }
      Lab::Ai.provider = fake

      post "/lab/agree/#{question.id}/answers", params: { body: 'alpha, basically' }
      expect(response.body).to include('Someone may have said this already')
      expect(question.lab_answers.where(body: 'alpha, basically')).not_to exist

      post "/lab/agree/#{question.id}/answers", params: { body: 'alpha, basically', confirm: '1' }
      expect(question.lab_answers.where(body: 'alpha, basically')).to exist
    end
  end

  describe Lab::Tally do
    it 'ranks the answer every group picks above one only a single group loves' do
      # Alpha: picked by both genders. Bravo: loved by men, ignored by women.
      vote(10, picks: ['Alpha answer', 'Bravo answer'], gender: 207)
      vote(10, picks: ['Alpha answer', 'Charlie answer'], gender: 208)
      tally = Lab::Tally.new(question)
      alpha = tally.row_for(answers[0].id)
      bravo = tally.row_for(answers[1].id)
      expect(alpha.groups[:gender]['Men'].rate).to eq(1.0)
      expect(bravo.groups[:gender]['Women'].rate).to eq(0.0)
      expect(alpha.score).to be > bravo.score
      expect(tally.ranked.first.answer).to eq(answers[0])
    end

    it 'gives no score until two groups have enough votes' do
      vote(Lab::Tally::MIN_SHOWN - 1, picks: ['Alpha answer'], gender: 207)
      expect(Lab::Tally.new(question).row_for(answers[0].id).score).to be_nil
    end
  end

  describe 'AI common-ground drafts' do
    it 'claims a drafting slot only every synth_every answers' do
      expect(question.claim_synthesis!).to be true    # 6 demo answers >= 3
      expect(question.claim_synthesis!).to be false   # nothing new since
      3.times { |i| question.lab_answers.create!(body: "new #{i}", author_kind: 'person') }
      expect(question.reload.claim_synthesis!).to be true
    end

    it 'stores the draft as an AI answer, keeping only real source ids' do
      vote(10, picks: ['Alpha answer', 'Bravo answer'], gender: 207)
      vote(10, picks: ['Alpha answer', 'Charlie answer'], gender: 208)
      fake = Object.new
      def fake.json(**) = { 'statement' => '"Shared ground."', 'based_on_ids' => [LabAnswer.find_by(body: 'Alpha answer').id, 999_999_999], 'note' => 'n' }
      Lab::Ai.provider = fake
      draft = Lab::Ai.draft_common_ground(question)
      expect(draft).to be_ai
      expect(draft.body).to eq('Shared ground.')
      expect(draft.source_ids).to eq([answers[0].id])
    end
  end
end
