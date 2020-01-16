class AddDefaultToSubscriptionsEnabled < ActiveRecord::Migration[5.2]
  def change
    change_column :subscriptions, :enabled, :boolean, default: true
  end
end
