class AddLockedAtToCommentThreads < ActiveRecord::Migration[7.2]
  def change
    add_column :comment_threads, :locked_at, :datetime, precision: nil
  end
end
