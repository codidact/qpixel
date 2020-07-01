class AddIndexesToVoteCounts < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :upvote_count
    add_index :posts, :downvote_count
  end
end
