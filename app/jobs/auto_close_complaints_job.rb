class AutoCloseComplaintsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    complaints = Complaint.where(status: 'reviewed')
                          .where(Arel.sql('status_updated_at <= ?', 14.days.ago))
    statuses = complaints.map do |complaint|
      complaint.update_status 'closed'
    end
    successful = statuses.map { |x| (x && 1) || 0 }.sum
    logger.info "Found #{complaints.size} inactive complaints, successfully closed #{successful} of them."
  end
end
