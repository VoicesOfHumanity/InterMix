# Chooses which answers a voter sees in a round of /lab/agree.
#
# A round mixes three kinds of answer, so that good answers keep being tested,
# new ones get a fair hearing, and AI common-ground drafts actually get voted on:
#   - an AI draft that is still short of votes, if there is one
#   - the current front-runners on the cross-group score
#   - the least-shown answers (new arrivals catch up quickly)
# Within each kind, answers this voter has seen least come first. Your own answers
# are never shown to you.
module Lab
  class Picker
    ROUND_SIZE = 5
    AI_EXPOSURE_TARGET = 40

    def initialize(question, participant, tally: nil, rng: Random.new)
      @question = question
      @participant = participant
      @tally = tally || Tally.new(question)
      @rng = rng
    end

    # include: an answer id the voter asked to see (e.g. "back that one instead")
    def pick(include: nil)
      pool = @tally.ranked.reject { |r| own?(r.answer) }
      return pool.map(&:answer).shuffle(random: @rng) if pool.size <= ROUND_SIZE

      seen = seen_counts
      fresh = ->(rows) { rows.sort_by { |r| [seen[r.answer.id] || 0, @rng.rand] } }
      chosen = []
      take = lambda do |rows, n|
        rows.each do |r|
          break if n <= 0
          next if chosen.include?(r)
          chosen << r
          n -= 1
        end
      end

      take.call(pool.select { |r| r.answer.id == include.to_i }, 1) if include
      take.call(fresh.call(pool.select { |r| r.answer.ai? && r.overall.shown < AI_EXPOSURE_TARGET }), 1)
      take.call(fresh.call(pool.select(&:score).first(6)), 2)
      take.call(pool.sort_by { |r| [r.overall.shown, seen[r.answer.id] || 0, @rng.rand] }, ROUND_SIZE)

      chosen.first(ROUND_SIZE).map(&:answer).shuffle(random: @rng)
    end

    private

    def own?(answer)
      @participant && answer.participant_id == @participant.id
    end

    def seen_counts
      return {} unless @participant
      @question.lab_votes.where(participant_id: @participant.id).group(:lab_answer_id).count
    end
  end
end
