class AddAuditIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :audit_logs, :log_type
    add_index :audit_logs, :event_type
  end
end
