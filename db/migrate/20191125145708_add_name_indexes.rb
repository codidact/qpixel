class AddNameIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :site_settings, :name
    add_index :privileges, :name
    add_index :post_types, :name
    add_index :post_history_types, :name
  end
end
