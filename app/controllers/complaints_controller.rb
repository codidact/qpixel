class ComplaintsController < ApplicationController
  def index
    render layout: 'without_sidebar'
  end

  def report
    @report_types = AppConfig.safety_center['report_types'].select { |_k, t| t['enabled'] }
    @content_types = AppConfig.safety_center['content_types']
    render layout: 'without_sidebar'
  end

  def create; end
end
