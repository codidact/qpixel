class AddNameToPrivileges < ActiveRecord::Migration
  def change
    add_column :privileges, :name, :string
  end
end
