class AddCommunityIdToCommentThreads < ActiveRecord::Migration[5.2]
  def change
    add_reference :comment_threads, :community, null: false
  end
end
