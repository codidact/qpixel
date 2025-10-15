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

  def report_types_select_options
    AppConfig.safety_center['report_types'].map { |k, v| [v['name'], k] }
  end

  def report_type(key)
    AppConfig.safety_center['report_types'][key]
  end
end
