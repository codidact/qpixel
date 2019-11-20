class RemoveActionNameFromPostHistoryTypes < ActiveRecord::Migration[5.0]
  def change
    remove_column :post_history_types, :action_name
  end
end
