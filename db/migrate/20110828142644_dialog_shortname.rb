class DialogShortname < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :shortname, :string
    add_column :dialogs, :created_by, :integer
    add_column :dialogs, :multigroup, :boolean, :default=>false
    add_column :dialogs, :group_id, :integer
    add_column :dialogs, :openness, :string
    add_column :dialogs, :max_mess_length, :integer
    add_column :dialogs, :signup_template, :text
    add_column :dialogs, :list_template, :text
    add_column :dialogs, :metamap_id, :integer
    add_column :dialogs, :metamap_vote_own, :string    # mainly, only, never
    add_index :dialogs, [:shortname], :length => {:shortname=>20}
  end

  def self.down
    remove_column :dialogs, :shortname
    remove_column :dialogs, :created_by
    remove_column :dialogs, :multigroup
    remove_column :dialogs, :group_id
    remove_column :dialogs, :openness
    remove_column :dialogs, :signup_template
    remove_column :dialogs, :list_template
    remove_column :dialogs, :metamap_id
    remove_column :dialogs, :metamap_vote_own
  end
end
