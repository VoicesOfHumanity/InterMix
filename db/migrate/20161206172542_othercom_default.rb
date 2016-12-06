class OthercomDefault < ActiveRecord::Migration
  def change
    change_column :participants, :othercom_email, :string, default: 'daily'
  end
end
