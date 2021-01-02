class AddDescriptionToLicenses < ActiveRecord::Migration[5.2]
  def change
    add_column :licenses, :description, :text
  end
end
