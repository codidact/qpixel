class AddCommunityToAuditLogs < ActiveRecord::Migration[5.2]
  def change
    add_reference :audit_logs, :community, foreign_key: true
  end
end
