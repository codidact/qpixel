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
    name = @subscription.name
    site_name = @subscription.community.name
    subject = if name.present?
                "Latest questions from your '#{name}' subscription on #{site_name}"
              else
                "Latest questions from your subscription on #{site_name}"
              end

    @subscription.update(last_sent_at: DateTime.now)
    from = "#{SiteSetting['SubscriptionSenderName']} <#{SiteSetting['SubscriptionSenderEmail']}>"
    to = @subscription.user.email
    mail from: from, to: to, subject: subject
    Rails.logger.info "Sent subscription mail (sub ID ##{@subscription.id}, to: '#{to}', name: '#{name}'"
  end
end
