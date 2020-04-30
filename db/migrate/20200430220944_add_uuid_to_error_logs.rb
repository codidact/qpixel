class AddUuidToErrorLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :error_logs, :uuid, :string
  end
end
