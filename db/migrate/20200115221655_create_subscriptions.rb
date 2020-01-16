class CreateSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :subscriptions do |t|
      t.string :type, null: false
      t.string :qualifier
      t.references :user, foreign_key: true
      t.boolean :enabled, null: false
      t.integer :frequency, null: false
      t.datetime :last_sent_at, null: false

      t.timestamps
    end
  end
end
