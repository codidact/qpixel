module ComplaintsHelper
  def content_types
    value_for('content_types') || []
  end

  def content_type(key)
    value_for('content_types', key)
  end

  def content_types_select_options
    select_options_for('content_types')
  end

  def outcomes_select_options
    select_options_for('outcomes')
  end

  def outcome(key)
    value_for('outcomes', key)
  end

  def report_types
    value_for('report_types') || []
  end

  def report_types_select_options
    select_options_for('report_types')
  end

  def report_type(key)
    value_for('report_types', key)
  end

  def enabled_report_types
    report_types.select { |_k, t| t['enabled'] }
  end

  def statuses
    value_for('statuses') || []
  end

  def statuses_select_options
    select_options_for('statuses')
  end

  def status(key)
    value_for('statuses', key)
  end

  private

  def value_for(*path)
    AppConfig.safety_center&.dig(*path)
  end

  def select_options_for(key)
    value_for(key)&.map { |k, v| [v['name'], k] } || []
  end
end
