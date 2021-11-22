class CreateMicroAuthTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :micro_auth_tokens do |t|
      t.references :micro_auth_app, foreign_key: true
      t.references :user, foreign_key: true
      t.string :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
