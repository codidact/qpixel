class AddIndexesToPosts < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :deleted
    add_index :posts, :parent_id
    add_index :posts, :user_id
    add_index :posts, :post_type_id
  end
end
