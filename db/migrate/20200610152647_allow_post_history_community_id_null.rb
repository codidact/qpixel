class AllowPostHistoryCommunityIdNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :post_histories, :community_id, true
  end
end
