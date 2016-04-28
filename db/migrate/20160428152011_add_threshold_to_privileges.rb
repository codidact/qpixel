class AddThresholdToPrivileges < ActiveRecord::Migration
  def change
    add_column :privileges, :threshold, :integer
  end
end
