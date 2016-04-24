class CreateSiteSettings < ActiveRecord::Migration
  def change
    create_table :site_settings do |t|
      t.string :name
      t.string :value

      t.timestamps null: false
    end
  end
end
