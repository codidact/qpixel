class AddDetachedAndPrivateCommentThreads < ActiveRecord::Migration[5.2]
  def change
    change_column_null :comment_threads, :post_id, true
    add_column :comment_threads, :is_private, :boolean, default: false
  end
end
