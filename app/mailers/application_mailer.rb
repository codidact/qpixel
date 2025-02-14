class ApplicationMailer < ActionMailer::Base
  default from: -> { "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>" }
  layout 'mailer'
end
