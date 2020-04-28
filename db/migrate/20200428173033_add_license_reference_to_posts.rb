class AddLicenseReferenceToPosts < ActiveRecord::Migration[5.2]
  def change
    add_reference :posts, :license, foreign_key: true
  end
end
