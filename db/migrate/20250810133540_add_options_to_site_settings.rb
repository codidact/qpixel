class AddOptionsToSiteSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :site_settings, :options, :string
  end
end
