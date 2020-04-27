class AddButtonTextToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :button_text, :string
  end
end
