class CreateBlockedItems < ActiveRecord::Migration[5.2]
  def change
    create_table :blocked_items do |t|
      t.string :type
      t.text :value
      t.datetime :expires
      t.boolean :automatic
      t.string :reason, null: true
      t.timestamps
    end
  end
end
