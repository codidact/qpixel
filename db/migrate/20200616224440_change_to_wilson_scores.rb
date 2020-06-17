class ChangeToWilsonScores < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :upvote_count, :integer, null: false, default: 0
    add_column :posts, :downvote_count, :integer, null: false, default: 0
  end
end
