class CreateSsoProfile < ActiveRecord::Migration[5.2]
  def change
    create_table :sso_profiles do |t|
      t.string :saml_identifier, null: false
      t.references :user, null: false, foreign_key: true
    end
  end
end