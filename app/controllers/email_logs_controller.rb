class EmailLogsController < ApplicationController
  skip_forgery_protection only: [:log]
  skip_before_action :set_globals, only: [:log]
  skip_before_action :distinguish_fake_community, only: [:log]
  skip_before_action :enforce_signed_in, only: [:log]

  def log
    message_type = request.headers['X-Amz-SNS-Message-Type']
    if ['SubscriptionConfirmation', 'Notification'].include? message_type
      verifier = Aws::SNS::MessageVerifier.new
      body = request.body.read
      if verifier.authentic? body
        aws_data = JSON.parse body
        if message_type == 'SubscriptionConfirmation'
          EmailLog.create(log_type: 'SubscriptionConfirmation', data: aws_data)
        else
          message_data = JSON.parse aws_data['Message']
          log_type = message_data['notificationType'] || message_data['eventType']
          destination = message_data['mail']['destination'].join(', ')
          EmailLog.create(log_type: log_type, destination: destination, data: aws_data['Message'])
        end
        render plain: 'OK'
      else
        render plain: "You're not AWS. Go away.", status: 401
      end
    end
  end
end
