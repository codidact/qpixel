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

    mail to: @subscription.user.email, subject: subject

    @subscription.update(last_sent_at: DateTime.now)
  end
end
