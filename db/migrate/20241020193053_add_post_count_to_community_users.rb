class AddPostCountToCommunityUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :community_users, :post_count, :integer, default: 0, null: false
  end
end
