class RenameTypeColumnOfBlockedItems < ActiveRecord::Migration[5.2]
  def change
    rename_column :blocked_items, :type, :item_type
  end
end
