class AddQrLoginAttributesToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :login_token, :string, unique: true
    add_column :users, :login_token_expires_at, :datetime
  end
end
