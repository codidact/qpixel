class AddFulltextIndexToPostsTitle < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :title, type: :fulltext
  end
end
