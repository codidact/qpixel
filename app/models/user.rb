# Represents a user. Most of the User's logic is controlled by Devise and its overrides. A user, as far as the
# application code (i.e. excluding Devise) is concerned, has many questions, answers, and votes.
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_and_belongs_to_many :privileges, dependent: :destroy
  has_many :notifications, dependent: :destroy

  after_create :set_initial_reputation

  validates :username, presence: true, length: { minimum: 3 }

  def has_privilege?(name)
    privilege = Privilege.where(name: name).first
    if privileges.include?(privilege) || is_admin || is_moderator
      true
    elsif privilege && reputation >= privilege.threshold
      privileges << privilege
      true
    else
      false
    end
  end

  def has_post_privilege?(name, post)
    if post.user == self
      true
    else
      self.has_privilege?(name)
    end
  end

  def create_notification(content, link)
    notification = Notification.create(content: content, link: link)
    notifications << notification
  end

  def unread_notifications
    notifications.where(is_read: false).count
  end

  def questions
    posts.where(post_type_id: Question.post_type_id)
  end

  def answers
    posts.where(post_type_id: Answer.post_type_id)
  end

  def website_domain
    website.nil? ? website : URI.parse(website).hostname
  end

  private

  def set_initial_reputation
    update(reputation: SiteSetting['NewUserInitialRep'])
  end
end
