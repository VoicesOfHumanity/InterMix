class UpdateCkeditorAssets < ActiveRecord::Migration
  def change
    #add_column :ckeditor_assets, :guid, :string, :limit => 10
    add_column :ckeditor_assets, :width, :integer
    add_column :ckeditor_assets, :height, :integer
  end
end
