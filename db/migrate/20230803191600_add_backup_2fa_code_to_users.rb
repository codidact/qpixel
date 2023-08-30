class AddBackup2faCodeToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :backup_2fa_code, :string
  end
end
