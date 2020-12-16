class AddIsFreelyEditableToPostTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :post_types, :is_freely_editable, :boolean, null: false, default: false
  end
end
