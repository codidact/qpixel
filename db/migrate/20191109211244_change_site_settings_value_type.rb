class ChangeSiteSettingsValueType < ActiveRecord::Migration[5.0]
  def change
    change_column :site_settings, :value, :text
  end
end
