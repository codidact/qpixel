class AddCidToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :cid, :string
  end
end
