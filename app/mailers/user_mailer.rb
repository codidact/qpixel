class UserMailer < ApplicationMailer
  helper :users

  default from: lambda {
    "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>"
  }

  def deletion_confirmation
    @user = params[:user]
    mail to: @user.email, subject: 'Your Codidact account has been deleted as you requested'
  end
end
