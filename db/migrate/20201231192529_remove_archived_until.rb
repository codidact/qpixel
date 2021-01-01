class RemoveArchivedUntil < ActiveRecord::Migration[5.2]
  def change
    remove_column :comment_threads, :archived_until
  end
end
