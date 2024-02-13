class SubscriptionMailer < ApplicationMailer
  helper UsersHelper

  def subscription
    @subscription = params[:subscription]
    @questions = @subscription.questions&.includes(:user) || []

    return if @subscription.type == 'Moderators'

    if @questions.empty?
      return
    end

    # Load request community to ensure we can access the settings/posts of the correct community
    RequestContext.community = @subscription.community
    site_name = @subscription.community.name
    subject = if @subscription.name.present?
                "Latest questions from your '#{@subscription.name}' subscription on #{site_name}"
              else
                "Latest questions from your subscription on #{site_name}"
              end

    @subscription.update(last_sent_at: DateTime.now)
    from = "#{SiteSetting['SubscriptionSenderName']} <#{SiteSetting['SubscriptionSenderEmail']}>"
    mail from: from, to: @subscription.user.email, subject: subject
  end
end
