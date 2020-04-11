class CreateCategoriesPostTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :categories_post_types, id: false, primary_key: [:category_id, :post_type_id] do |t|
      t.bigint :category_id, null: false
      t.bigint :post_type_id, null: false
    end
  end
end
