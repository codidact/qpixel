class AddDeletedToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :deleted, :boolean, null: false, default: false
    add_column :users, :deleted_at, :datetime
    add_reference :users, :deleted_by, index: true, foreign_key: { to_table: :users }

    add_column :community_users, :deleted, :boolean, null: false, default: false
    add_column :community_users, :deleted_at, :datetime
    add_reference :community_users, :deleted_by, index: true, foreign_key: { to_table: :users }
  end
end
