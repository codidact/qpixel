class CreateAbilityQueues < ActiveRecord::Migration[5.2]
  def change
    create_table :ability_queues do |t|
      t.references :community_user
      t.text :comment, null: true
      t.boolean :completed
      t.timestamps
    end
  end
end
