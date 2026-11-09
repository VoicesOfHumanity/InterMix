# Tables for the experimental "Can humanity agree on anything?" section at /lab/agree.
#
# Deliberately separate from items/ratings: lab answers must not leak into the forum,
# moon mailings or ActivityPub while this is a prototype, and if the experiment is
# dropped these three tables can be dropped with it.
#
# Explicitly InnoDB + utf8mb4: backups use --single-transaction now, which only gives
# a consistent snapshot of InnoDB tables (see STATUS 2026-08-15).
class CreateLabTables < ActiveRecord::Migration[8.0]
  TABLE_OPTIONS = 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'

  def change
    create_table :lab_questions, options: TABLE_OPTIONS do |t|
      t.string  :title, null: false
      t.text    :intro
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      # An AI common-ground draft is attempted every `synth_every` new human answers
      t.integer :synth_every, null: false, default: 8
      t.integer :answers_at_last_synth, null: false, default: 0
      t.timestamps
    end

    create_table :lab_answers, options: TABLE_OPTIONS do |t|
      t.integer :lab_question_id, null: false
      t.integer :participant_id
      t.string  :author_kind, null: false, default: 'person'   # person | ai | demo
      t.string  :body, null: false, limit: 300
      t.string  :status, null: false, default: 'active'         # active | hidden
      # Who wrote it, frozen at the time - used to show answers "from different people"
      t.integer :gender_id
      t.integer :generation_id
      t.string  :region, limit: 2
      # For AI drafts: the answer ids it was drafted from, and the model's reasoning
      t.string  :source_answer_ids
      t.text    :ai_note
      t.timestamps
    end
    add_index :lab_answers, [:lab_question_id, :status]
    add_index :lab_answers, :participant_id

    # One row per answer SHOWN in a round; picked says whether it was one of the
    # (up to) two chosen. picked/shown per group is the pick rate.
    create_table :lab_votes, options: TABLE_OPTIONS do |t|
      t.integer :lab_question_id, null: false
      t.integer :lab_answer_id, null: false
      t.integer :participant_id
      t.string  :round_token, null: false, limit: 32
      t.boolean :picked, null: false, default: false
      t.boolean :demo, null: false, default: false
      # Voter's profile at the time of voting, so tallies need no joins and do not
      # shift when someone later edits their profile
      t.integer :gender_id
      t.integer :generation_id
      t.string  :country_code, limit: 2
      t.string  :region, limit: 2
      t.datetime :created_at, null: false
    end
    add_index :lab_votes, [:lab_question_id, :lab_answer_id]
    add_index :lab_votes, [:participant_id, :lab_question_id]
    add_index :lab_votes, [:round_token, :lab_answer_id], unique: true
  end
end
