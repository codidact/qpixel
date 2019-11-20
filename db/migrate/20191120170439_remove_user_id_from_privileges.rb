class RemoveUserIdFromPrivileges < ActiveRecord::Migration[5.0]
  def change
    remove_column :privileges, :user_id
  end
end
