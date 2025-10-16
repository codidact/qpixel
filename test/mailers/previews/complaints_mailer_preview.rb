# Preview all emails at http://localhost:3000/rails/mailers/complaints_mailer
class ComplaintsMailerPreview < ActionMailer::Preview
  def new_complaint
    ComplaintsMailer.with(complaint: Complaint.first).new_complaint
  end

  def complaint_reviewed
    ComplaintsMailer.with(complaint: Complaint.where(status: 'reviewed').first).complaint_reviewed
  end

  def legal_deletion
    ComplaintsMailer.with(post: Post.unscoped.last, complaint: Complaint.last).legal_deletion
  end
end
