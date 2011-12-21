class ParticipForumSettings < ActiveRecord::Migration
  def self.up
    add_column :participants, :forum_settings, :text
  end

  def self.down
    remove_column :participants, :forum_settings
  end
end
