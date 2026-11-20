class AddVersionToErrorLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :error_logs, :version, :string
  end
end
