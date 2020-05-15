class AddPostIndexes < ActiveRecord::Migration[5.2]
  def change
    change_column :posts, :att_source, :string
    add_index :posts, :att_source
    add_index :posts, :tags_cache
  end
end
