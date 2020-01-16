class AddNameToSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :name, :string
  end
end
