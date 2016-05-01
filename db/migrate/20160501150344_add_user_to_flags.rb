class AddUserToFlags < ActiveRecord::Migration
  def change
    add_reference :flags, :user, index: true, foreign_key: true
  end
end
