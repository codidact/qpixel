class AddUserToPrivileges < ActiveRecord::Migration
  def change
    add_reference :privileges, :user, index: true, foreign_key: true
  end
end
