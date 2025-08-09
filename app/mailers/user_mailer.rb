class UserMailer < ApplicationMailer
  helper :application, :users

  def deletion_confirmation
    @user = params[:user]
    @host = params[:host]
    @community = params[:community]
    mail to: @user.email, subject: 'Your Codidact account has been deleted as you requested',
         from: "#{SiteSetting['NoReplySenderName', community: @community]} " \
               "<#{SiteSetting['NoReplySenderEmail', community: @community]}>"
  end
end
