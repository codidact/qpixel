class RemoveExcerptMarkdown < ActiveRecord::Migration[5.2]
  def change
    remove_column :tags, :excerpt_markdown
  end
end
