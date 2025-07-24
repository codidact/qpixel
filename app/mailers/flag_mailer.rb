class FlagMailer < ApplicationMailer
  helper :application, :post_types, :users, :tags, :posts, :comments

  def flag_escalated
    @flag = params[:flag]
    emails = User.joins(:community_user).where(is_global_admin: true)
                 .or(User.joins(:community_user)
                         .where(community_users: { is_admin: true, community_id: @flag.community_id }))
                 .select(:email).map(&:email)
    from = "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>"
    to = SiteSetting['NoReplySenderEmail']
    mail from: from, to: to, bcc: emails, subject: "New flag escalation on #{@flag.community.name}"
  end
end
