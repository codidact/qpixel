ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
                                       access_key_id: Rails.application.credentials.ses_access_key,
                                       secret_access_key: Rails.application.credentials.ses_secret_key,
                                       server: 'email.us-east-1.amazonaws.com',
                                       signature_version: 4
