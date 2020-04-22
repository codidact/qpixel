class AddMinTrustLevelToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :min_trust_level, :integer
  end
end
