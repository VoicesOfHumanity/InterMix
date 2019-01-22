class ParticipantDualCountry < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :country_code2, :string, limit: 2, after: :country_name
    add_column :participants, :country_name2, :string, after: :country_code2
  end
end
