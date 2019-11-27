class AddBodyMarkdownToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :body_markdown, :text
  end
end
