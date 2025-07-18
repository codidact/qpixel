class UserMailer < ApplicationMailer
  helper :application, :users

  def deletion_confirmation
    @user = params[:user]
    @host = params[:host]
    mail to: @user.email, subject: 'Your Codidact account has been deleted as you requested',
         from: "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>"
  end
end
