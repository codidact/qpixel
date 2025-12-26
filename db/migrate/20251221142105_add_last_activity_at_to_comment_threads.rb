class AddLastActivityAtToCommentThreads < ActiveRecord::Migration[7.2]
  def change
    add_column :comment_threads, :last_activity_at, :datetime
  end
end
