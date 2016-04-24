class AddRepAndNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :reputation, :integer
    add_column :users, :username, :string
  end
end
