class AddUserToWarnings < ActiveRecord::Migration[5.2]
  def change
    add_reference :warnings, :user, null: true
    change_column_null :warnings, :community_user_id, true
  end
end
