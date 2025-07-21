# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def deletion_confirmation
    @user = User.last
    UserMailer.with(user: @user).deletion_confirmation
  end
end
