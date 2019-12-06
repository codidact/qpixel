class AddTransferredContentToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :transferred_content, :boolean, default: false
  end
end
