class AdminMailer < ApplicationMailer
  default from: 'moderators-noreply@codidact.com'

  def to_moderators
    @subject = params[:subject]
    @body_markdown = params[:body_markdown]
    query = 'SELECT DISTINCT u.email FROM subscriptions s INNER JOIN users u ON s.user_id = u.id ' \
            "INNER JOIN community_users cu ON cu.user_id = u.id WHERE s.type = 'moderators' AND " \
            '(u.is_global_admin = 1 OR u.is_global_moderator = 1 OR cu.is_admin = 1 OR cu.is_moderator = 1)'
    emails = ActiveRecord::Base.connection.execute(query).to_a.flatten
    mail subject: "Codidact Moderators: #{@subject}", to: 'moderators-noreply@codidact.org', bcc: emails
  end
end
