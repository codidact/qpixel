class AddDefaultFilterToCategory < ActiveRecord::Migration[7.0]
  def change
    add_reference :categories, :default_filter, foreign_key: { to_table: :filters }, null: true
  end
end
