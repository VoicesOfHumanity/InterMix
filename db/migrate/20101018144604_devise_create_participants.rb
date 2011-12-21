class DeviseCreateParticipants < ActiveRecord::Migration
  def self.up
    create_table(:participants) do |t|
      
      t.string :first_name
      t.string :last_name
      t.string :title
      t.text :self_description
      t.string :address1
      t.string :address2
      t.string :city
      t.string :county_code, :limit => 15
      t.string :county_name
      t.string :state_code, :limit=>10
      t.string :state_name
      t.string :country_code, :limit=>2
      t.string :country_name
      t.string :zip
      t.string :phone
      t.string :metropolitan_area
      t.string :bioregion
      t.string :faith_tradition
      t.string :status
      
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable
      t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable
      t.boolean :sysadmin, :default => false
      t.timestamps
    end

    add_index :participants, [:last_name,:first_name], :length => {:last_name=>20, :first_name=>20}
    add_index :participants, [:country_code,:state_code,:city], :length => {:city=>20}
    add_index :participants, :email,                :unique => true
    add_index :participants, :reset_password_token, :unique => true
    add_index :participants, :confirmation_token,   :unique => true
    # add_index :participants, :unlock_token,         :unique => true
  end

  def self.down
    drop_table :participants
  end
end
