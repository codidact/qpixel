class MoveCategoryPostTypesToIdPrimaryKey < ActiveRecord::Migration[5.2]
  def change
    add_column :categories_post_types, :id, :primary_key
    add_index :categories_post_types, [:category_id, :post_type_id], unique: true
  end
end
