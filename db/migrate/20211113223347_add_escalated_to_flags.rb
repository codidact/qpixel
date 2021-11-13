class AddEscalatedToFlags < ActiveRecord::Migration[5.2]
  def change
    add_column :flags, :escalated, :boolean, null: false, default: false
    add_column :flags, :escalated_at, :datetime
    add_column :flags, :escalation_comment, :text
    add_reference :flags, :escalated_by, foreign_key: { to_table: :users }
  end
end
