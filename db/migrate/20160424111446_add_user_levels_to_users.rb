class AddUserLevelsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_moderator, :boolean
    add_column :users, :is_admin, :boolean
  end
end
