class ComplaintsMailer < ApplicationMailer
  helper :complaints

  def new_complaint
    @complaint = params[:complaint]
    mail(from: "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>",
         subject: 'Your report has been received',
         to: @complaint.email)
  end

  def complaint_reviewed
    @complaint = params[:complaint]
    mail(from: "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>",
         subject: 'Your report has been reviewed',
         to: @complaint.email)
  end
end
