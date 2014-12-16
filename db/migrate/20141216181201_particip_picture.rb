class ParticipPicture < ActiveRecord::Migration
  def self.up
      add_attachment :participants, :picture
    end

    def self.down
      remove_attachment :participants, :picture
      end
end
