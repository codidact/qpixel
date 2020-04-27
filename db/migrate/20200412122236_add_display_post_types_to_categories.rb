class AddDisplayPostTypesToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :display_post_types, :text
  end
end
