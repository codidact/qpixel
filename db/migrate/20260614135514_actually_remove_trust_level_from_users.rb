class ActuallyRemoveTrustLevelFromUsers < ActiveRecord::Migration[7.2]
  def up
    remove_column :users, :trust_level, if_exists: true
  end

  def down
    # this migration is intentionally not idempotent
  end
end
