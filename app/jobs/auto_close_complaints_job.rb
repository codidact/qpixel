class AutoCloseComplaintsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    complaints = Complaint.where(status: 'reviewed')
                          .where(Arel.sql('status_updated_at <= ?', 14.days.ago))
    complaints.each do |complaint|
      complaint.update_status 'closed'
    end
  end
end
