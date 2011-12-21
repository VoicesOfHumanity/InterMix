class DialogLogo < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :logo_file_name,    :string
    add_column :dialogs, :logo_content_type, :string
    add_column :dialogs, :logo_file_size,    :integer
    add_column :dialogs, :logo_updated_at,   :datetime
  end

  def self.down
    remove_column :dialogs, :logo_file_name
    remove_column :dialogs, :logo_content_type
    remove_column :dialogs, :logo_file_size
    remove_column :dialogs, :logo_updated_at
  end
end
