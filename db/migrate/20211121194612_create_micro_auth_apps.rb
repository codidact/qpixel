class CreateMicroAuthApps < ActiveRecord::Migration[5.2]
  def change
    create_table :micro_auth_apps do |t|
      t.string :name
      t.string :app_id
      t.string :public_key
      t.string :secret_key
      t.text :description
      t.string :auth_domain
      t.references :user, foreign_key: true
      t.boolean :active, null: false, default: true
      t.references :deactivated_by, foreign_key: { to_table: :users }
      t.datetime :deactivated_at
      t.string :deactivate_comment

      t.timestamps
    end

    add_index :micro_auth_apps, :app_id
    add_index :micro_auth_apps, :public_key
    add_index :micro_auth_apps, :secret_key
  end
end
