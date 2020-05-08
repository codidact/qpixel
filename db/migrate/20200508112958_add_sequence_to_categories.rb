class AddSequenceToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :sequence, :integer
    add_index :categories, :sequence
  end
end
