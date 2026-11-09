# /lab/agree - "Can humanity agree on anything? Let's find out."
#
# A candidate for reviving Voices of Humanity, kept apart from the rest of the site
# until Roger has seen it: own tables (lab_*), own layout, no menu links.
#
#   pick a question -> see 5 answers -> pick the 2 you agree with most -> see how
#   your picks compare across genders, generations and regions -> add your own
#
# Voting needs a login because the profile (gender, generation, country) is what
# the results are tabulated by. Results are public.
class LabController < ApplicationController
  layout 'lab'

  before_action :load_question, except: [:index, :login, :visitor]
  before_action :require_login, only: [:pick, :create_answer]
  before_action :require_sysadmin, only: [:hide_answer, :synthesize]

  MAX_ANSWERS_PER_QUESTION = 5
  MAX_ANSWERS_VISITOR = 50   # the visitor account is shared by everyone who uses it

  def index
    @questions = LabQuestion.active.to_a
    @leaders = @questions.to_h { |q| [q.id, Lab::Tally.new(q).ranked.find(&:score)] }
  end

  def show
    @tally = Lab::Tally.new(@question)
    unless participant_signed_in?
      @preview = @tally.ranked.first(3)
      return render :teaser
    end
    @answers = Lab::Picker.new(@question, current_participant, tally: @tally).pick(include: params[:include])
    @token = SecureRandom.hex(12)
    session[:lab_round] = { 'token' => @token, 'question_id' => @question.id, 'ids' => @answers.map(&:id) }
    @snapshot = Lab::Groups.snapshot(current_participant)
    @answer_count = own_answers.count
  end

  def pick
    round = session[:lab_round] || {}
    unless round['token'] == params[:token] && round['question_id'] == @question.id
      return redirect_to(lab_question_path(@question), alert: 'That round had expired - here is a fresh one.')
    end
    shown = Array(round['ids']).map(&:to_i)
    picked = Array(params[:picked]).map(&:to_i).uniq & shown
    unless picked.size.between?(1, 2)
      return redirect_to(lab_question_path(@question), alert: 'Pick one or two answers.')
    end

    snap = Lab::Groups.snapshot(current_participant)
    LabVote.transaction do
      shown.each do |answer_id|
        LabVote.create!(snap.merge(lab_question_id: @question.id, lab_answer_id: answer_id,
                                   participant_id: current_participant.id, round_token: params[:token],
                                   picked: picked.include?(answer_id)))
      end
    end
    session.delete(:lab_round)
    flash[:lab_picked] = picked
    redirect_to lab_results_path(@question)
  end

  def results
    @tally = Lab::Tally.new(@question)
    @rows = @tally.ranked
    @picked = Array(flash[:lab_picked]).map(&:to_i)
    @snapshot = participant_signed_in? ? Lab::Groups.snapshot(current_participant) : {}
    @memberships = Lab::Groups.memberships(@snapshot)
  end

  def create_answer
    body = params[:body].to_s.squish
    unless body.length.between?(3, LabAnswer::MAX_LENGTH)
      return redirect_to(lab_question_path(@question),
                         alert: "Answers need to be between 3 and #{LabAnswer::MAX_LENGTH} characters.")
    end
    limit = current_participant.id == VISITOR_ID ? MAX_ANSWERS_VISITOR : MAX_ANSWERS_PER_QUESTION
    if own_answers.count >= limit && !current_participant.sysadmin
      return redirect_to(lab_question_path(@question), alert: "You've already given #{limit} answers to this question.")
    end

    if params[:confirm] != '1' && Lab::Ai.enabled?
      candidates = @question.live_answers.order(id: :desc).limit(200).to_a
      @duplicate, @reason = Lab::Ai.find_duplicate(@question, body, candidates)
      if @duplicate
        @body = body
        return render :duplicate
      end
    end

    snap = Lab::Groups.snapshot(current_participant)
    @question.lab_answers.create!(body: body, participant_id: current_participant.id, author_kind: 'person',
                                  gender_id: snap[:gender_id], generation_id: snap[:generation_id],
                                  region: snap[:region])
    LabSynthesizeJob.perform_later(@question.id) if Lab::Ai.enabled? && @question.claim_synthesis!
    redirect_to lab_question_path(@question), notice: 'Your answer is in. Other people will start seeing it in their rounds.'
  end

  def hide_answer
    @question.lab_answers.where(id: params[:answer_id]).update_all(status: 'hidden')
    redirect_to lab_results_path(@question), notice: 'Answer hidden.'
  end

  def synthesize
    return redirect_to(lab_results_path(@question), alert: 'No AI key is configured.') unless Lab::Ai.enabled?
    answer = Lab::Ai.draft_common_ground(@question)
    if answer
      redirect_to lab_results_path(@question), notice: "AI draft added: “#{answer.body}”"
    else
      redirect_to lab_results_path(@question), alert: 'The AI did not produce a draft (too few answers, or an API error - see the log).'
    end
  end

  # Sign in, then come back to where you were in the lab
  def login
    session[:lab_return] = safe_return
    redirect_to '/participants/sign_in'
  end

  # One-click guest access for trying it out (shared visitor account)
  def visitor
    if !participant_signed_in? && (visitor = Participant.find_by(id: VISITOR_ID))
      sign_in(:participant, visitor)
    end
    redirect_to safe_return
  end

  private

  def load_question
    @question = LabQuestion.find_by(id: params[:id])
    @question = nil if @question && !@question.active && !current_participant&.sysadmin
    raise ActionController::RoutingError, 'Not Found' unless @question
  end

  def require_login
    redirect_to lab_question_path(@question) unless participant_signed_in?
  end

  def require_sysadmin
    head :forbidden unless current_participant&.sysadmin
  end

  def own_answers
    @question.lab_answers.where(participant_id: current_participant.id)
  end

  def safe_return
    r = params[:return].to_s
    r.start_with?('/lab/') && !r.start_with?('//') ? r : lab_index_path
  end
end
