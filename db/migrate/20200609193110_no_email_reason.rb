class NoEmailReason < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :no_email_reason, :string, default: '', after: :no_email
  end
end
