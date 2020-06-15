class AddUniqueIndexToPostsTags < ActiveRecord::Migration[5.2]
  def change
    add_index :posts_tags, [:post_id, :tag_id], unique: true
  end
end
