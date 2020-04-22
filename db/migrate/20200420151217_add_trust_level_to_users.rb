class AddTrustLevelToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :trust_level, :integer
  end
end
