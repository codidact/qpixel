# Preview all emails at http://localhost:3000/rails/mailers/summary_mailer
class SummaryMailerPreview < ActionMailer::Preview
  def content_summary
    test_timeframe = 1.year
    staff = User.where(staff: true)
    posts = Post.unscoped.qa_only.where(created_at: test_timeframe.ago..DateTime.now)
                .includes(:community, :user)
    flags = Flag.unscoped.where(created_at: test_timeframe.ago..DateTime.now)
                .includes(:post, :community, :user)
    comments = Comment.unscoped.where(created_at: test_timeframe.ago..DateTime.now)
                      .includes(:user, :post, :comment_thread, post: :community)
    users = User.where(created_at: test_timeframe.ago..DateTime.now).includes(:community_users)

    SummaryMailer.with(to: staff.first.email, posts: posts.to_a, flags: flags.to_a, comments: comments.to_a, users: users.to_a)
                 .content_summary
  end
end
