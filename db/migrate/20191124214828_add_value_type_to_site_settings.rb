class AddValueTypeToSiteSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :site_settings, :value_type, :string, null: false
  end
end
