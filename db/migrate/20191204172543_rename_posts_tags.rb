class RenamePostsTags < ActiveRecord::Migration[5.2]
  def change
    rename_column :posts, :tags, :tags_cache
  end
end
