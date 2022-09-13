class AddPostToThreadFollowers < ActiveRecord::Migration[7.0]
  def change
    add_reference :thread_followers, :post, null: true, foreign_key: true
    change_column_null :thread_followers, :comment_thread_id, true
  end
end
