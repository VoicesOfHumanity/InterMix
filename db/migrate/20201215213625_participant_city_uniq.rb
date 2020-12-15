class ParticipantCityUniq < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :city_uniq, :string, limit: 128, default: '', after: :city
    add_column :participants, :country_iso3, :string, limit: 3, default: '', after: :country_code
    add_column :participants, :country2_iso3, :string, limit: 3, default: '', after: :country_code2
  end
end
