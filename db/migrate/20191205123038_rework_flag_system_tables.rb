class ReworkFlagSystemTables < ActiveRecord::Migration[5.2]
  def change
    add_column :flags, :status, :string
    add_column :flags, :message, :text
    add_column :flags, :handled_by_id, :integer

    drop_table :flag_statuses
  end
end
