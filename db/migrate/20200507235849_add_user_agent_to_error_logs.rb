class AddUserAgentToErrorLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :error_logs, :user_agent, :string
  end
end
