# Represents a user. Most of the User's logic is controlled by Devise and its overrides. A user, as far as the
# application code (i.e. excluding Devise) is concerned, has many questions, answers, and votes.
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable, :omniauthable

  has_many :posts, dependent: :nullify
  has_many :votes, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :community_users, dependent: :destroy
  has_many :flags, dependent: :nullify
  has_many :error_logs, dependent: :nullify
  has_one :community_user, -> { for_context }, autosave: true, dependent: :destroy
  has_one_attached :avatar, dependent: :destroy
  has_many :suggested_edits, dependent: :nullify
  has_many :suggested_edits_decided, class_name: 'SuggestedEdit', foreign_key: 'decided_by_id', dependent: :nullify
  has_many :audit_logs, dependent: :nullify
  has_many :audit_logs_related, class_name: 'AuditLog', dependent: :nullify, as: :related
  has_many :mod_warning_author, class_name: 'ModWarning', foreign_key: 'author_id', dependent: :nullify

  validates :username, presence: true, length: { minimum: 3, maximum: 50 }
  validates :login_token, uniqueness: { allow_blank: true }
  validate :no_links_in_username
  validate :username_not_fake_admin
  validate :no_blank_unicode_in_username
  validate :email_domain_not_blocklisted
  validate :is_not_blocklisted
  validate :email_not_bad_pattern

  delegate :reputation, :reputation=, :privilege?, :privilege, :trust_level, to: :community_user

  after_create :send_welcome_tour_message

  def self.list_includes
    includes(:posts, :avatar_attachment)
  end

  def self.search(term)
    where('username LIKE ?', "#{sanitize_sql_like(term)}%")
  end

  # This class makes heavy use of predicate names, and their use is prevalent throughout the codebase
  # because of the importance of these methods.
  # rubocop:disable Naming/PredicateName
  def has_post_privilege?(name, post)
    if post.user == self
      true
    else
      privilege?(name)
    end
  end

  def create_notification(content, link)
    notification = Notification.create(content: content, link: link)
    notifications << notification
  end

  def unread_count
    notifications.unscoped.where(user: self, is_read: false).count
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
    is_global_moderator || community_user&.is_moderator || is_admin || community_user&.privilege?('mod') || false
  end

  def is_admin
    is_global_admin || community_user&.is_admin || false
  end

  def rtl_safe_username
    "#{username}\u202D"
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

  def no_blank_unicode_in_username
    not_valid = !username.scan(/[\u200B-\u200C\u200D\uFEFF]/).empty?
    if not_valid
      errors.add(:username, 'may not contain blank unicode characters')
    end
  end

  def email_domain_not_blocklisted
    return unless File.exist?(Rails.root.join('../.qpixel-domain-blocklist.txt'))
    return unless saved_changes.include? 'email'

    blocklist = File.read(Rails.root.join('../.qpixel-domain-blocklist.txt')).split("\n")
    email_domain = email.split('@')[-1]
    matched = blocklist.select { |x| email_domain == x }
    if matched.any?
      errors.add(:base, ApplicationRecord.useful_err_msg.sample)
      matched_domains = matched.map { |d| "equals: #{d}" }
      AuditLog.block_log(event_type: 'user_email_domain_blocked',
                         comment: "email: #{email}\n#{matched_domains.join("\n")}\nsource: file")
    end
  end

  def is_not_blocklisted
    return unless saved_changes.include? 'email'

    email_domain = email.split('@')[-1]
    is_mail_blocked = BlockedItem.emails.where(value: email)
    is_mail_host_blocked = BlockedItem.email_hosts.where(value: email_domain)
    if is_mail_blocked.any? || is_mail_host_blocked.any?
      errors.add(:base, ApplicationRecord.useful_err_msg.sample)
      if is_mail_blocked.any?
        AuditLog.block_log(event_type: 'user_email_blocked', related: is_mail_blocked.first,
                           comment: "email: #{email}\nfull match to: #{is_mail_blocked.first.value}")
      end
      if is_mail_host_blocked.any?
        AuditLog.block_log(event_type: 'user_email_domain_blocked', related: is_mail_host_blocked.first,
                           comment: "email: #{email}\ndomain match to: #{is_mail_host_blocked.first.value}")
      end
    end
  end

  def email_not_bad_pattern
    return unless File.exist?(Rails.root.join('../.qpixel-email-patterns.txt'))
    return unless saved_changes.include? 'email'

    patterns = File.read(Rails.root.join('../.qpixel-email-patterns.txt')).split("\n")
    matched = patterns.select { |p| email.match? Regexp.new(p) }
    if matched.any?
      errors.add(:base, ApplicationRecord.useful_err_msg.sample)
      matched_patterns = matched.map { |p| "matched: #{p}" }
      AuditLog.block_log(event_type: 'user_email_pattern_match',
                         comment: "email: #{email}\n#{matched_patterns.join("\n")}")
    end
  end

  def ensure_community_user!
    community_user || create_community_user(reputation: SiteSetting['NewUserInitialRep'])
  end

  def no_links_in_username
    if %r{(?:http|ftp)s?://(?:\w+\.)+[a-zA-Z]{2,10}}.match?(username)
      errors.add(:username, 'cannot contain links')
      AuditLog.block_log(event_type: 'user_username_link_blocked',
                         comment: "username: #{username}")
    end
  end

  def extract_ip_from(request)
    # Customize this to your environment: if you're not behind a reverse proxy like Cloudflare, you probably
    # don't need this (or you can change it to another header if that's what your reverse proxy uses).
    request.headers['CF-Connecting-IP'] || request.ip
  end

  def send_welcome_tour_message
    return if id == -1 || RequestContext.community.nil?

    create_notification("👋 Welcome to #{SiteSetting['SiteName'] || 'Codidact'}! Take our tour to find out " \
                        'how this site works.', '/tour')
  end

  def block(reason)
    user_email = email
    user_ip = [last_sign_in_ip]

    if current_sign_in_ip
      user_ip << current_sign_in_ip
    end

    BlockedItem.create(item_type: 'email', value: user_email, expires: DateTime.now + 180.days,
                       automatic: true, reason: "#{reason}: #" + id.to_s)
    user_ip.compact.uniq.each do |ip|
      BlockedItem.create(item_type: 'ip', value: ip, expires: 180.days.from_now,
                         automatic: true, reason: "#{reason}: #" + @user.id.to_s)
    end
  end
  # rubocop:enable Naming/PredicateName
end
