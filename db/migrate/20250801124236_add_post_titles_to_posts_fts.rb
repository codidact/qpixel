# initial post FTS did not include titles
class AddPostTitlesToPostsFts < ActiveRecord::Migration[7.2]
  def change
    remove_index :posts, :body_markdown
    add_index :posts, [:body_markdown, :title], type: :fulltext
  end
end
