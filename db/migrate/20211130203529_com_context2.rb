class ComContext2 < ActiveRecord::Migration[5.2]
  def change
    add_column :communities, :context2, :string, default: "", after: :context_code
    add_column :communities, :context_code2, :string, default: "", after: :context2
  end
end
