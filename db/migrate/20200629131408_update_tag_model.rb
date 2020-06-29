class UpdateTagModel < ActiveRecord::Migration[5.2]
  def change
    remove_column :tags, :description
    add_column :tags, :wiki_markdown, :text
    add_column :tags, :excerpt_markdown, :text
    add_column :tags, :wiki, :text
    add_column :tags, :excerpt, :text
  end
end
