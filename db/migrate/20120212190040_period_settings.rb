class PeriodSettings < ActiveRecord::Migration
  def change
    add_column :periods, :max_characters, :integer
    add_column :periods, :metamap_vote_own, :string
    add_column :periods, :default_message, :text
    add_column :periods, :required_message, :boolean, :default => true
    add_column :periods, :required_subject, :boolean, :default => true
    add_column :periods, :max_messages, :integer, :default => 0
    add_column :periods, :new_message_title, :string
    add_column :periods, :allow_replies, :boolean, :default => true
    add_column :periods, :required_meta, :boolean, :default => true
    add_column :periods, :value_calc, :string, :default => "total"
    add_column :periods, :profiles_visible, :boolean, :default => true
    add_column :periods, :names_visible_voting, :boolean, :default => true
    add_column :periods, :names_visible_general, :boolean, :default => true
    add_column :periods, :in_voting_round, :boolean, :default => false
    add_column :periods, :posting_open, :boolean, :default => true
    add_column :periods, :voting_open, :boolean, :default => true
  end
end
