class AddPostDefaults < ActiveRecord::Migration[5.0]
  def change
    change_column :posts, :deleted, :boolean, null: false, default: false
    change_column :posts, :closed, :boolean, null: false, default: false
  end
end
