class AddTagSetReferenceToCategories < ActiveRecord::Migration[5.2]
  def change
    add_reference :categories, :tag_set, foreign_key: true
  end
end
