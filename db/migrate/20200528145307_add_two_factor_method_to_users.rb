class AddTwoFactorMethodToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :two_factor_method, :string
    User.where(enabled_2fa: true).update_all(two_factor_method: 'app')
  end
end
