class ComplaintsMailer < ApplicationMailer
  helper :application, :post_types, :complaints

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

  def legal_deletion
    @post = params[:post]
    @complaint = params[:complaint]
    mail(from: "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>",
         subject: 'Your post has been removed for legal reasons',
         to: @post.user.email)
  end

  def staff_reply
    @complaint = params[:complaint]
    @comment = params[:comment]
    mail(from: "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>",
         subject: 'Your report has a reply from a member of staff',
         to: @complaint.email)
  end
end
