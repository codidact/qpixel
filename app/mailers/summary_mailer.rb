class SummaryMailer < ApplicationMailer
  TIMEFRAME = 30.minutes

  helper :application, :post_types, :users

  def content_summary
    @posts = params[:posts]
    @flags = params[:flags]
    @comments = params[:comments]
    @users = params[:users]

    mail(from: "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>",
         subject: 'Codidact Content Summary',
         to: params[:to])
  end
end
