Rails.application.configure do
  if config.action_mailer.delivery_method == :ses
    Aws.config.update(region: 'us-east-1')

    access_key = Rails.application.credentials.ses_access_key
    secret_key = Rails.application.credentials.ses_secret_key
    credentials = Aws::Credentials.new(access_key, secret_key)

    Aws.config[:ses] = { credentials: credentials }

    ses_client = Aws::SESV2::Client.new

    config.action_mailer.ses_v2_settings = { sesv2_client: ses_client }
  end
end
