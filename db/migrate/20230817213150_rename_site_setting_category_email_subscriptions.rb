class RenameSiteSettingCategoryEmailSubscriptions < ActiveRecord::Migration[7.0]
  def change
    SiteSetting.where(category: 'EmailSubscriptions').update_all(category: 'Email')
  end
end
