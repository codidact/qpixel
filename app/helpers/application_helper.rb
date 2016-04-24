module ApplicationHelper
  def get_setting(name)
    setting = SiteSetting.find_by_name name
    return setting.value
  end
end
