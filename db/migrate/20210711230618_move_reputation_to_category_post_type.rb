class MoveReputationToCategoryPostType < ActiveRecord::Migration[5.2]
  def change
    add_column :categories_post_types, :upvote_rep, :integer, null: false, default: 0
    add_column :categories_post_types, :downvote_rep, :integer, null: false, default: 0
    remove_column :post_types, :upvote_rep
    remove_column :post_types, :downvote_rep
  end
end
