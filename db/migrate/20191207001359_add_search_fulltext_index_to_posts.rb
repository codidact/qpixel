class AddSearchFulltextIndexToPosts < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :body_markdown, type: :fulltext
  end
end
