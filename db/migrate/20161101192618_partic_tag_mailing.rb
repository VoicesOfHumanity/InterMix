class ParticTagMailing < ActiveRecord::Migration
  def change
    add_column :participants, :mycom_email, :string, default: 'daily', after: :system_email
    add_column :participants, :othercom_email, :string, default: 'never', after: :mycom_email
  end
end
