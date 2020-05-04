class AddTwoFactorTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :two_factor_token, :string
    add_column :users, :enabled_2fa, :boolean, default: false
  end
end
