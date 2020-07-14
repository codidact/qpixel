# Represents a user. Most of the User's logic is controlled by Devise and its overrides. A user, as far as the
# application code (i.e. excluding Devise) is concerned, has many questions, answers, and votes.
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_and_belongs_to_many :privileges, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :community_users, dependent: :destroy
  has_many :flags, dependent: :nullify
  has_many :error_logs, dependent: :nullify
  has_one :community_user, -> { for_context }, autosave: true
  has_one_attached :avatar, dependent: :destroy
  has_many :suggested_edits, dependent: :destroy
  has_many :suggested_edits_decided, class_name: 'SuggestedEdit', foreign_key: 'decided_by_id', dependent: :nullify

  has_many :mod_warning_author, class_name: 'ModWarning', foreign_key: 'author_id', dependent: :nullify

  validates :username, presence: true, length: { minimum: 3, maximum: 50 }
  validates :login_token, uniqueness: { allow_nil: true, allow_blank: true }
  validate :no_links_in_username
  validate :username_not_fake_admin

  delegate :reputation, :reputation=, to: :community_user

  def self.list_includes
    includes(:posts, :avatar_attachment)
  end

  def self.search(term)
    where('username LIKE ?', "#{sanitize_sql_like(term)}%")
  end

  # This class makes heavy use of predicate names, and their use is prevalent throughout the codebase
  # because of the importance of these methods.
  # rubocop:disable Naming/PredicateName

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
      has_privilege?(name)
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

  def is_moderator
    is_global_moderator || community_user&.is_moderator || is_admin || false
  end

  def is_admin
    is_global_admin || community_user&.is_admin || false
  end

  def trust_level
    attributes['trust_level'] || recalc_trust_level
  end

  def recalc_trust_level
    # Temporary hack until we have some things to actually calculate based on.
    trust = if is_admin || is_global_admin
              6
            elsif is_moderator || is_global_moderator
              5
            else
              1
            end
    update(trust_level: trust)
    trust
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

  def no_links_in_username
    if %r{(?:http|ftp)s?://(?:\w+\.)+[a-zA-Z]{2,10}}.match?(username)
      errors.add(:username, 'cannot contain links')
    end
  end

  protected

  def extract_ip_from(request)
    # Customize this to your environment: if you're not behind a reverse proxy like Cloudflare, you probably
    # don't need this (or you can change it to another header if that's what your reverse proxy uses).
    request.headers['X-Forwarded-For']
  end

  # rubocop:enable Naming/PredicateName
end
