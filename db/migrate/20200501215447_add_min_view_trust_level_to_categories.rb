class AddMinViewTrustLevelToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :min_view_trust_level, :integer
  end
end
