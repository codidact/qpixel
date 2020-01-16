class AllowNullSubscriptionsLastSent < ActiveRecord::Migration[5.2]
  def change
    change_column :subscriptions, :last_sent_at, :datetime, null: true
  end
end
