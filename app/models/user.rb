# Represents a user. Most of the User's logic is controlled by Devise and its overrides. A user, as far as the
# application code (i.e. excluding Devise) is concerned, has many questions, answers, and votes.
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :questions
  has_many :answers
  has_many :votes
  has_many :privileges
  has_many :notifications

  # Checks whether or not a user has the given privilege. For efficiency, initially checks if the privilege is in the
  # user's <tt>privileges</tt> association and returns true if so; otherwise checks reputation and assigns the
  # privilege if the user has enough rep. This method should not be used to secure administrator-only privileges, as
  # both admins and mods are assumed to have the privilege.
  def has_privilege?(name)
    privilege = Privilege.where(:name => name).first
    if privileges.include?(privilege) || is_admin || is_moderator
      return true
    elsif privilege && reputation >= privilege.threshold
      privileges << privilege
      return true
    else
      return false
    end
  end

  def create_notification(content, link)
    notification = Notification.create(content: content, link: link)
    notifications << notification
  end
end
