class UserMailer < ApplicationMailer
  helper :application, :users

  default from: lambda {
    "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>"
  }

  def deletion_confirmation
    @user = params[:user]
    @host = params[:host]
    mail to: @user.email, subject: 'Your Codidact account has been deleted as you requested'
  end
end
