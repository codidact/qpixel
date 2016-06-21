class RenameUserAttributes < ActiveRecord::Migration
  def change
    rename_column :suspicious_votes, :from_user, :from_user_id
    rename_column :suspicious_votes, :to_user, :to_user_id
  end
end
