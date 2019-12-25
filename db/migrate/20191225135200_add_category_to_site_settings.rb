class AddCategoryToSiteSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :site_settings, :category, :string
    add_index :site_settings, :category
  end
end