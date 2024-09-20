class AddPostCountToCommunityUsers < ActiveRecord::Migration[7.0]
  def self.up
    add_column :community_users, :post_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :community_users, :post_count
  end
end
