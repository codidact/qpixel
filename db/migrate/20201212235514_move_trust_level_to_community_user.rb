class MoveTrustLevelToCommunityUser < ActiveRecord::Migration[5.2]
  def change
    add_column :community_users, :trust_level, :integer
    remove_column :users, :trust_level
  end
end
