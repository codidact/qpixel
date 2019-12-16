class AddUsersUsernameIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :users, :username
  end
end
