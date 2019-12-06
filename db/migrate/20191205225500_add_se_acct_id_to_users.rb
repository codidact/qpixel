class AddSeAcctIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :se_acct_id, :integer
  end
end
