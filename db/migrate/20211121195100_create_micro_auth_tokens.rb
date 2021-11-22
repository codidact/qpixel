class CreateMicroAuthTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :micro_auth_tokens do |t|
      t.references :app, foreign_key: { to_table: :micro_auth_apps }
      t.references :user, foreign_key: true
      t.string :token
      t.datetime :expires_at
      t.text :scope
      t.string :code
      t.datetime :code_expires_at
      t.text :redirect_uri

      t.timestamps
    end
  end
end
