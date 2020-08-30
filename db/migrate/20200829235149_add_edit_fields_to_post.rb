class AddEditFieldsToPost < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :last_edited_at, :datetime
    add_column :posts, :last_edited_by_id, :bigint
    add_index :posts, :last_edited_by_id
  end
end
