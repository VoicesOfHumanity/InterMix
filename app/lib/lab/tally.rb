# Pick rates and the cross-group ("bridging") score for /lab/agree.
#
# Every round shows a voter 5 answers and they pick 2, so a random answer is picked
# about 40% of the times it is shown. For each answer and each group we compute
#
#   rate = picked / shown                       (what we display)
#   adjusted = (picked + PRIOR * BASE) / (shown + PRIOR)
#
# The adjusted rate pulls small samples toward 40%, so an answer seen 3 times and
# picked 3 times does not outrank one seen 80 times and picked 60. An answer's
# cross-group score is its LOWEST adjusted rate across all groups that have seen it at
# least MIN_SHOWN times. It is only high if every group tends to pick it - an answer
# loved by one group and ignored by another scores low, however popular it is overall.
module Lab
  class Tally
    BASE = 0.4
    PRIOR = 5.0
    MIN_SHOWN = 5

    Cell = Struct.new(:shown, :picked) do
      def rate
        shown.zero? ? nil : picked.to_f / shown
      end

      def adjusted
        (picked + PRIOR * BASE) / (shown + PRIOR)
      end

      def enough?
        shown >= MIN_SHOWN
      end
    end

    Row = Struct.new(:answer, :overall, :groups, :score, keyword_init: true) do
      # groups: { dimension_key => { group_label => Cell } }
      def qualifying_groups
        groups.values.flat_map(&:values).count(&:enough?)
      end
    end

    def initialize(question)
      @question = question
    end

    def rows
      @rows ||= build_rows
    end

    def row_for(answer_id)
      rows.find { |r| r.answer.id == answer_id }
    end

    # Answers with a score, best cross-group agreement first; unscored ones after,
    # most-shown first.
    def ranked
      rows.sort_by { |r| [r.score ? 0 : 1, -(r.score || 0), -r.overall.shown] }
    end

    def total_rounds
      @question.lab_votes.distinct.count(:round_token)
    end

    def total_voters
      @question.participant_count
    end

    private

    def build_rows
      answers = @question.live_answers.to_a
      overall = cells(@question.lab_votes.group(:lab_answer_id))
      by_dim = Groups::DIMENSIONS.to_h do |key, dim|
        [key, cells(@question.lab_votes.group(:lab_answer_id, dim[:column]))]
      end

      answers.map do |a|
        groups = Groups::DIMENSIONS.to_h do |key, dim|
          per_group = dim[:groups].to_h do |value, label|
            [label, by_dim[key][[a.id, value]] || Cell.new(0, 0)]
          end
          [key, per_group]
        end
        qualifying = groups.values.flat_map(&:values).select(&:enough?)
        score = qualifying.size >= 2 ? qualifying.map(&:adjusted).min : nil
        Row.new(answer: a, overall: overall[a.id] || Cell.new(0, 0), groups: groups, score: score)
      end
    end

    # { group_key => Cell } from a grouped relation
    def cells(relation)
      shown = relation.count
      picked = relation.where(picked: true).count
      shown.to_h { |k, n| [k, Cell.new(n, picked[k] || 0)] }
    end
  end
end
