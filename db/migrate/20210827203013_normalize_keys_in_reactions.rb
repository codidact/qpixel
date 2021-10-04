class NormalizeKeysInReactions < ActiveRecord::Migration[5.2]
  def change
    rename_column :reactions, :posts_id, :post_id
    rename_column :reactions, :reaction_types_id, :reaction_type_id
    rename_column :reactions, :users_id, :user_id
    rename_column :reactions, :comments_id, :comment_id
  end
end
