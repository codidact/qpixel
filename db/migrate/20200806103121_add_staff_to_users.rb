class AddStaffToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :staff, :boolean, null: false, default: false
  end
end
