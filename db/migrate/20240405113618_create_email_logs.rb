class CreateEmailLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :email_logs do |t|
      t.string :log_type
      t.string :destination
      t.text :data

      t.timestamps
    end
  end
end
