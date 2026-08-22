class AddNotNullDefaultToCategories < ActiveRecord::Migration[7.2]
  def change
    Category.unscoped.where(min_view_trust_level: nil).update_all(min_view_trust_level: 0)
    change_column :categories, :min_view_trust_level, :integer, default: 0, null: false
    add_index :categories, :min_view_trust_level
  end
end
