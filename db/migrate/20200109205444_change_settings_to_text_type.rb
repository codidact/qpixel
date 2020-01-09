class ChangeSettingsToTextType < ActiveRecord::Migration[5.2]
  def change
    SiteSetting.find_by(name: 'AskingGuidance').update(value_type: 'text')
    SiteSetting.find_by(name: 'AnsweringGuidance').update(value_type: 'text')
  end
end
