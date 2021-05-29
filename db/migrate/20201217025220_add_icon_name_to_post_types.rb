class AddIconNameToPostTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :post_types, :icon_name, :string
  end
end
