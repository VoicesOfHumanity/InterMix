class CommunityVoices < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :voice_of_humanity, :string
    add_column :communities, :voice_of_women, :string
    add_column :communities, :voice_of_men, :string
    add_column :communities, :voice_of_young, :string
    add_column :communities, :voice_of_middleage, :string
    add_column :communities, :voice_of_old, :string
  end
end
