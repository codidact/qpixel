class AddAttributionFieldsToPost < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :att_source, :text
    add_column :posts, :att_license_name, :string
    add_column :posts, :att_license_link, :string
  end
end
