class AddLicenseReferenceToCategories < ActiveRecord::Migration[5.2]
  def change
    add_reference :categories, :license, foreign_key: true
  end
end
