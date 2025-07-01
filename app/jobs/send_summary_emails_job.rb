class SendSummaryEmailsJob < ApplicationJob
  queue_as :default

  def perform
    staff = User.where(staff: true)
    posts = Post.unscoped.qa_only.where(created_at: SummaryMailer::TIMEFRAME.ago..DateTime.now)
                .includes(:community, :user)
    flags = Flag.unscoped.where(created_at: SummaryMailer::TIMEFRAME.ago..DateTime.now)
                .includes(:post, :community, :user)
    comments = Comment.unscoped.where(created_at: SummaryMailer::TIMEFRAME.ago..DateTime.now)
                      .includes(:user, :post, :comment_thread, post: :community)
    users = User.where(created_at: SummaryMailer::TIMEFRAME.ago..DateTime.now).includes(:community_users)
    staff.each do |u|
      SummaryMailer.with(to: u.email, posts: posts, flags: flags, comments: comments, users: users)
                   .content_summary
                   .deliver_later
    end
  end
end
