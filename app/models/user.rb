# Represents a user. Most of the User's logic is controlled by Devise and its overrides. A user, as far as the
# application code (i.e. excluding Devise) is concerned, has many questions, answers, and votes.
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :privileges, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Checks whether or not a user has the given privilege. For efficiency, initially checks if the privilege is in the
  # user's <tt>privileges</tt> association and returns true if so; otherwise checks reputation and assigns the
  # privilege if the user has enough rep. This method should not be used to secure administrator-only privileges, as
  # both admins and mods are assumed to have the privilege.
  def has_privilege?(name)
    privilege = Privilege.where(name: name).first
    if privileges.include?(privilege) || is_admin || is_moderator
      return true
    elsif privilege && reputation >= privilege.threshold
      privileges << privilege
      return true
    else
      return false
    end
  end

  # Basically the same as <tt>User#has_privilege?</tt>, but checks privileges with relation to the post as well. OPs
  # always have every privilege on their own posts.
  def has_post_privilege?(name, post)
    if post.user == self
      return true
    else
      return self.has_privilege?(name)
    end
  end

  # Creates and adds a notification to the instance user's notification stack.
  def create_notification(content, link)
    notification = Notification.create(content: content, link: link)
    notifications << notification
  end

  # Returns a count of unread notifications for the instance user. Does not return the notifications themselves; that
  # should be done by calling the API action from <tt>NotificationsController#index</tt>.
  def unread_notifications
    return notifications.where(is_read: false).count
  end

  def questions
    posts.where(post_type_id: 1)
  end

  def answers
    posts.where(post_type_id: 2)
  end
end
