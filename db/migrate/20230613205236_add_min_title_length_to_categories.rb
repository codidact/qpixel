class AddMinTitleLengthToCategories < ActiveRecord::Migration[7.0]
  def change
    add_column :categories, :min_title_length, :integer, null: false, default: 15
    add_column :categories, :min_body_length, :integer, null: false, default: 30
  end
end
