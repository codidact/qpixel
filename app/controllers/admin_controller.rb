# Web controller. Provides authenticated actions for use by administrators.
class AdminController < ApplicationController
  before_action :verify_admin

  def index
  end

  def error_reports
    errored = `grep "Completed 500" log/#{Rails.env}.log`.split("\n")
    request_ids = errored.map { |l| /\[([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})\]/.match(l)&.try(:[], 1) }.compact
    @error_count = errored.size
    @report_count = request_ids.size
    @reports = request_ids.map { |uuid| [uuid, `grep "#{uuid}" log/#{Rails.env}.log`.split("\n")] }.to_h
  end
end
