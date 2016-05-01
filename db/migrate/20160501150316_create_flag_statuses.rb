class CreateFlagStatuses < ActiveRecord::Migration
  def change
    create_table :flag_statuses do |t|
      t.string :result
      t.string :message

      t.timestamps null: false
    end
  end
end
