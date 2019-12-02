class AddProfileMarkdownToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :profile_markdown, :text
  end
end
