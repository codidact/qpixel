class AddIsHomepageToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :is_homepage, :boolean
  end
end
