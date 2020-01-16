class SubscriptionMailer < ApplicationMailer
  def subscription
    @subscription = params[:subscription]
    @questions = @subscription.questions.includes(:user) || []
    if @questions.size == 0
      return
    end

    mail to: @subscription.user.email,
         subject: @subscription.name.present? ? "Latest questions from your '#{@subscription.name}' subscription on Writing" :
                      'Latest questions from your subscription on Writing'
  end
end
