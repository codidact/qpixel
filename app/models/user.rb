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
  has_many :subscriptions, dependent: :destroy
  has_many :community_users, dependent: :destroy
  has_one :community_user, -> { for_context }, autosave: true
  has_one_attached :avatar, dependent: :destroy

  validates :username, presence: true, length: { minimum: 3 }
  validate :username_not_fake_admin

  delegate :reputation, :reputation=, :is_moderator, :is_admin, to: :community_user

  def self.list_includes
    includes(:posts, :avatar_attachment)
  end

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

  def unread_count
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

  def username_not_fake_admin
    admin_badge = SiteSetting['AdminBadgeCharacter']
    mod_badge = SiteSetting['ModBadgeCharacter']

    [admin_badge, mod_badge].each do |badge|
      if badge.present? && username.include?(badge)
        errors.add(:username, "may not include the #{badge} character")
      end
    end
  end

  def ensure_community_user!
    community_user || create_community_user(reputation: SiteSetting['NewUserInitialRep'])
  end
end
