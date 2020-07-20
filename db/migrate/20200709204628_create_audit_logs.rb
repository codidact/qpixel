class CreateAuditLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :audit_logs do |t|
      t.string :log_type
      t.string :event_type
      t.references :related, polymorphic: true
      t.references :user, foreign_key: true
      t.text :comment

      t.timestamps
    end
  end
end
