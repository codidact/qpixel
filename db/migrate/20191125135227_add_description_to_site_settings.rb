class AddDescriptionToSiteSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :site_settings, :description, :text
  end
end
