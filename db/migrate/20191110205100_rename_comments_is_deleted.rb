class RenameCommentsIsDeleted < ActiveRecord::Migration[5.0]
  def change
    rename_column :comments, :is_deleted, :deleted
  end
end
