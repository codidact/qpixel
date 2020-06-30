class SubscriptionMailer < ApplicationMailer
  def subscription
    @subscription = params[:subscription]
    @questions = @subscription.questions&.includes(:user) || []

    return if @subscription.type == 'Moderators'

    if @questions.empty?
      return
    end

    site_name = @subscription.community.name
    subject = if @subscription.name.present?
                "Latest questions from your '#{@subscription.name}' subscription on #{site_name}"
              else
                "Latest questions from your subscription on #{site_name}"
              end

    @subscription.update(last_sent_at: DateTime.now)
    mail from: 'subscriptions@codidact.com', to: @subscription.user.email, subject: subject
  end
end
