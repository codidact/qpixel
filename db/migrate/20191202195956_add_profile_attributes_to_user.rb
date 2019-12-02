class AddProfileAttributesToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :profile, :text
    add_column :users, :website, :text
    add_column :users, :twitter, :string
  end
end
