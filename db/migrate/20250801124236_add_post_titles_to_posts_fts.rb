# initial post FTS did not include titles
class AddPostTitlesToPostsFts < ActiveRecord::Migration[7.2]
  def change
    remove_index :posts, :body_markdown, if_exists: true, type: :fulltext
    add_index :posts, [:body_markdown, :title], if_not_exists: true, type: :fulltext
  end
end
