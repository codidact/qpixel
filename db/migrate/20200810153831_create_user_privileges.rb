class CreateUserPrivileges < ActiveRecord::Migration[5.2]
  def change
    create_table :user_privileges do |t|
      t.references :community_user, foreign_key: true
      t.references :trust_level, foreign_key: true
      t.boolean :is_suspended, default: false
      t.datetime :suspension_end, null: true
      t.text :suspension_message, null: true
      t.timestamps
    end
  end
end
