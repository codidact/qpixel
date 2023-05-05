class CreateCategoryFilterDefaults < ActiveRecord::Migration[7.0]
  def change
    create_table :category_filter_defaults do |t|
      t.references :user, null: false, foreign_key: true
      t.references :filter, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
    end
  end
end
