module ComplaintsHelper
  def statuses_select_options
    AppConfig.safety_center['statuses'].map { |k, v| [v['name'], k] }
  end

  def status(key)
    AppConfig.safety_center['statuses'][key]
  end

  def outcomes_select_options
    AppConfig.safety_center['outcomes'].map { |k, v| [v['name'], k] }
  end

  def outcome(key)
    AppConfig.safety_center['outcomes'][key]
  end
end
