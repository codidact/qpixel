class SubscriptionMailer < ApplicationMailer
  def subscription
    @subscription = params[:subscription]
    @questions = @subscription.questions&.includes(:user) || []
    if @questions.empty?
      return
    end

    subject = if @subscription.name.present?
                "Latest questions from your '#{@subscription.name}' subscription on Writing"
              else
                'Latest questions from your subscription on Writing'
              end

    @subscription.update(last_sent_at: DateTime.now)
    mail from: 'subscriptions@codidact.com', to: @subscription.user.email, subject: subject
  end
end
