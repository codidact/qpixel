class AllowPostCommunityIdNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :posts, :community_id, true
  end
end
