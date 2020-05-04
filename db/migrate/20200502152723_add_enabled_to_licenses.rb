class AddEnabledToLicenses < ActiveRecord::Migration[5.2]
  def change
    add_column :licenses, :enabled, :boolean, default: 1
  end
end
