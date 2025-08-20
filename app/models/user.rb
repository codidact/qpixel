class User < ApplicationRecord
  include ::UsernameValidations
  include ::UserRateLimits
  include ::UserMerge
  include ::Timestamped
  include ::SoftDeletable
  include ::SamlInit
  include ::Inspectable
  include ::Identity

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable, :omniauthable, :saml_authenticatable

  has_many :apps, class_name: 'MicroAuth::App', dependent: :destroy
  has_many :posts, dependent: :nullify
  has_many :votes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :community_users, dependent: :destroy
  has_many :flags, dependent: :nullify
  has_many :error_logs, dependent: :destroy
  has_one :community_user, -> { for_context }, autosave: true, dependent: :destroy
  has_one_attached :avatar, dependent: :destroy
  has_many :suggested_edits, dependent: :nullify
  has_many :suggested_edits_decided, class_name: 'SuggestedEdit', foreign_key: 'decided_by_id', dependent: :nullify
  has_many :audit_logs, dependent: :nullify
  has_many :audit_logs_related, class_name: 'AuditLog', dependent: :nullify, as: :related
  has_many :mod_warning_author, class_name: 'ModWarning', foreign_key: 'author_id', dependent: :nullify
  has_many :comments, dependent: :nullify
  has_many :comment_threads_deleted, class_name: 'CommentThread', foreign_key: :deleted_by_id, dependent: :nullify
  has_many :comment_threads_locked, class_name: 'CommentThread', foreign_key: :locked_by_id, dependent: :nullify
  has_many :category_filter_defaults, dependent: :destroy
  has_many :filters, dependent: :destroy
  has_many :user_websites, dependent: :destroy
  accepts_nested_attributes_for :user_websites

  validates :login_token, uniqueness: { allow_blank: true, case_sensitive: false }
  validate :email_domain_not_blocklisted
  validate :not_blocklisted?
  validate :email_not_bad_pattern

  delegate :reputation, :reputation=, :privilege?, :privilege, to: :community_user

  alias_attribute :name, :username

  # Gets users appropriately scoped for a given user
  # @param user [User] user to check
  # @return [ActiveRecord::Relation<User>]
  def self.accessible_to(user)
    (user&.at_least_moderator? ? User.all : User.undeleted)
  end

  def self.list_includes
    includes(:posts, :avatar_attachment)
  end

  def self.search(term)
    where('username LIKE ?', "%#{sanitize_sql_like(term)}%")
  end

  # Safely gets the user's trust level even if they don't have a community user
  # @return [Integer] user's trust level
  def trust_level
    community_user&.trust_level || 0
  end

  # Is the user a new user?
  # @return [Boolean] check result
  def new?
    !privilege?('unrestricted')
  end

  # Does the user own a given post or its parent, if any?
  # @param post [Post] post to check
  # @return [Boolean] check result
  def owns_post_or_parent?(post)
    post.user_id == id || post.parent&.user_id == id
  end

  # This class makes heavy use of predicate names, and their use is prevalent throughout the codebase
  # because of the importance of these methods.
  def post_privilege?(name, post)
    post.user == self || privilege?(name)
  end

  # Can the user archive a given comment thread?
  # @param thread [CommentThread] thread to archive
  # @return [Boolean] check result
  def can_archive?(thread)
    privilege?('flag_curate') && !thread.archived?
  end

  # Can the user unarchive a given comment thread?
  # @param thread [CommentThread] thread to archive
  # @return [Boolean] check result
  def can_unarchive?(thread)
    privilege?('flag_curate') && thread.archived?
  end

  # Can the user decide (approve or reject) a given suggested edit?
  # @param edit [SuggestedEdit] edit to check
  # @return [Boolean] check result
  def can_decide?(edit)
    edit.post.present? && can_update?(edit.post, edit.post.post_type)
  end

  alias can_approve? can_decide?
  alias can_reject? can_decide?

  # Can the user comment on a given post?
  # @param post [Post] post to check
  # @return [Boolean] check result
  def can_comment_on?(post)
    return true if at_least_moderator?

    post.comments_allowed? && !comment_rate_limited?(post)
  end

  # Can the user close a given post?
  # @param post [Post] post to check
  # @return [Boolean] check result
  def can_close?(post)
    return false unless post.closeable?
    return false if post.locked?

    privilege?('flag_close') || post.user&.same_as?(self)
  end

  # Can the user delete a given target?
  # @param target [ApplicationRecord] record to delete
  # @return [Boolean] check result
  def can_delete?(target)
    privilege?('flag_curate') && !target.deleted?
  end

  # Can the user undelete a given target?
  # @param target [ApplicationRecord] record to undelete
  # @return [Boolean] check result
  def can_undelete?(target)
    privilege?('flag_curate') && target.deleted?
  end

  # Can the user lock a given target?
  # @param target [Lockable] record to lock
  # @return [Boolean] check result
  def can_lock?(target)
    privilege?('flag_curate') && !target.locked?
  end

  # Can the user unlock a given target?
  # @param target [Lockable] record to unlock
  # @return [Boolean] check result
  def can_unlock?(target)
    privilege?('flag_curate') && target.locked?
  end

  # Can the user post in the current category?
  # @param category [Category, nil] category to check
  # @return [Boolean] check result
  def can_post_in?(category)
    category.blank? || category.min_trust_level.blank? || category.min_trust_level <= trust_level
  end

  # Can the user reply to a given comment thread?
  # @param [CommentThread] thread to check
  # @return [Boolean] check result
  def can_reply_to?(thread)
    return true if at_least_moderator?

    can_comment_on?(thread.post) && !thread.read_only?
  end

  # Can the user see a given category at all?
  # @param category [Category] category to check
  # @return [Boolean] check result
  def can_see_category?(category)
    category_trust_level = category.min_view_trust_level || -1
    trust_level >= category_trust_level
  end

  # Is the user allowed to see deleted posts?
  # @return [Boolean] check result
  def can_see_deleted_posts?
    privilege?('flag_curate') || false
  end

  # Can the user push a given post type to network?
  # @param post_type [PostType] type of the post to be pushed
  # @return [Boolean] check result
  def can_push_to_network?(post_type)
    post_type.system? && (is_global_moderator || is_global_admin)
  end

  # Can the user directly update a given post?
  # @param post [Post] updated post (owners can unilaterally update)
  # @param post_type [PostType] type of the post (some are freely editable)
  # @return [Boolean] check result
  def can_update?(post, post_type)
    return false unless can_post_in?(post.category)

    post_privilege?('edit_posts', post) || at_least_moderator? ||
      (post_type.is_freely_editable && privilege?('unrestricted'))
  end

  def metric(key)
    Rails.cache.fetch("community_user/#{community_user.id}/metric/#{key}", expires_in: 24.hours) do
      case key
      when 'p'
        Post.qa_only.undeleted.by(self).count
      when '1'
        Post.undeleted.by(self).where(post_type: PostType.top_level).count
      when '2'
        Post.undeleted.by(self).where(post_type: PostType.second_level).count
      when 's'
        Vote.for(self).where(vote_type: 1).count - Vote.for(self).where(vote_type: -1).count
      when 'v'
        Vote.for(self).count
      when 'V'
        votes.count
      when 'E'
        PostHistory.by(self).of_type('post_edited').count
      end
    end
  end

  def create_notification(content, link)
    notifications.create!(content: content, link: link)
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

  def valid_websites_for
    user_websites.where.not(url: [nil, '']).order(position: :asc)
  end

  def ensure_websites
    pos = user_websites.size
    while pos < UserWebsite::MAX_ROWS
      pos += 1
      UserWebsite.create(user_id: id, position: pos)
    end
  end

  # Is the user a global admin (ensures consistent return type & naming scheme)?
  # @return [Boolean] check result
  def global_admin?
    is_global_admin || false
  end

  # Is the user a global moderator (ensures consistent return type & naming scheme)?
  # @return [Boolean] check result
  def global_moderator?
    is_global_moderator || false
  end

  # Is the user either a global admin or an admin on the current community?
  # @return [Boolean] check result
  def admin?
    global_admin? || community_user&.admin? || false
  end

  # Is the user either a global moderator or a moderator on the current community?
  # @return [Boolean] check result
  def moderator?
    global_moderator? || community_user&.moderator? || false
  end

  # Is the user at least a moderator, meaning the user is either:
  # - a global moderator or a moderator on the current community
  # - a global admin or an admin on the current community
  # - has an explicit moderator privilege on the current community
  # @return [Boolean] check result
  def at_least_moderator?
    moderator? || admin? || community_user&.privilege?('mod') || false
  end

  # Is the user neither a moderator nor an admin (global or on the current community)?
  # @return [Boolean] check result
  def standard?
    !at_least_moderator?
  end

  # Is the user is a global moderator or a global admin?
  # @return [Boolean] check result
  def at_least_global_moderator?
    global_moderator? || global_admin? || false
  end

  # Which communities is this user a moderator (local or global) on?
  # @return [Community[]] list of communities
  def moderator_communities
    if global_moderator?
      Community.all
    else
      Community.joins(:community_users).where(community_users: { user_id: id, is_moderator: true })
    end
  end

  # Which communities is this user an admin (local or global) of?
  # @return [Community[]] list of communities
  def admin_communities
    if global_admin?
      Community.all
    else
      Community.joins(:community_users).where(community_users: { user_id: id, is_admin: true })
    end
  end

  # Is the user a moderator on a given community?
  # @param community_id [Integer] community id to check for
  # @return [Boolean] check result
  def moderator_on?(community_id)
    cu = community_users.where(community_id: community_id).first
    cu&.at_least_moderator? || cu&.privilege?('mod') || false
  end

  # Does the user have a profile on a given community?
  # @param community_id [Integer] id of the community to check
  # @return [Boolean] check result
  def profile_on?(community_id)
    cu = community_users.where(community_id: community_id).first
    !cu&.user_id.nil? || false
  end

  def reputation_on(community_id)
    cu = community_users.where(community_id: community_id).first
    cu&.reputation || 1
  end

  def post_count_on(community_id)
    cu = community_users.where(community_id: community_id).first
    cu&.post_count || 0
  end

  # Does the user have an ability on a given community?
  # @param community_id [Integer] community id to check for
  # @param ability_internal_id [String] internal ability id
  # @return [Boolean] check result
  def ability_on?(community_id, ability_internal_id)
    cu = community_users.where(community_id: community_id).first
    if cu&.at_least_moderator? || cu&.privilege?('mod')
      true
    elsif cu.nil?
      false
    else
      Ability.unscoped do
        UserAbility.joins(:ability).where(community_user_id: cu&.id, is_suspended: false,
                                          ability: { internal_id: ability_internal_id }).exists?
      end
    end
  end

  def rtl_safe_username
    "#{username}\u202D"
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

  def not_blocklisted?
    return true unless saved_changes.include? 'email'

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
    return unless changes.include? 'email'

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

  def block(reason, length: 180.days)
    user_email = email
    user_ip = [last_sign_in_ip]

    if current_sign_in_ip
      user_ip << current_sign_in_ip
    end

    BlockedItem.create(item_type: 'email', value: user_email, expires: length.from_now,
                       automatic: true, reason: "#{reason}: #" + id.to_s)
    user_ip.compact.uniq.each do |ip|
      BlockedItem.create(item_type: 'ip', value: ip, expires: length.from_now,
                         automatic: true, reason: "#{reason}: #" + id.to_s)
    end
  end

  def preferences
    global_key = "prefs.#{id}"
    community_key = "prefs.#{id}.community.#{RequestContext.community_id}"
    {
      global: AppConfig.preferences.select { |_, v| v['global'] }.transform_values { |v| v['default'] }
                       .merge(RequestContext.redis.hgetall(global_key)),
      community: AppConfig.preferences.select { |_, v| v['community'] }.transform_values { |v| v['default'] }
                          .merge(RequestContext.redis.hgetall(community_key))
    }
  end

  def category_preference(category_id)
    category_key = "prefs.#{id}.category.#{RequestContext.community_id}.category.#{category_id}"
    AppConfig.preferences.select { |_, v| v['category'] }.transform_values { |v| v['default'] }
             .merge(RequestContext.redis.hgetall(category_key))
  end

  def validate_prefs!
    global_key = "prefs.#{id}"
    community_key = "prefs.#{id}.community.#{RequestContext.community_id}"
    {
      global_key => AppConfig.preferences.reject { |_, v| v['community'] },
      community_key => AppConfig.preferences.select { |_, v| v['community'] }
    }.each do |key, prefs|
      saved = RequestContext.redis.hgetall(key)
      valid_prefs = prefs.keys
      deprecated = saved.except(*valid_prefs).map { |k, _v| k }
      unless deprecated.empty?
        RequestContext.redis.hdel key, *deprecated
      end
    end
  end

  def preference(name, community: false)
    preferences[community ? :community : :global][name]
  end

  def active_flags_on?(post)
    !post.flags.where(user: self, status: nil).empty?
  end

  def active_flags(post)
    post.flags.where(user: self, status: nil)
  end

  def do_soft_delete(attribute_to)
    AuditLog.moderator_audit(event_type: 'user_delete', related: self, user: attribute_to,
                             comment: attributes_print(join: "\n"))
    assign_attributes(deleted: true, deleted_by_id: attribute_to.id, deleted_at: DateTime.now,
                      username: "user#{id}", email: "#{id}@deleted.localhost",
                      password: SecureRandom.hex(32))
    skip_reconfirmation!
    save
  end

  # Gets user's post counts by post type
  # @return [Hash{Integer => Integer}]
  def posts_by_post_type
    posts.undeleted.group(Arel.sql('posts.post_type_id')).count(Arel.sql('posts.post_type_id'))
  end

  # Gets user's vote counts by vote type
  # @return [Hash{Integer => Integer}]
  def votes_by_type
    votes.group(:vote_type).count(:vote_type)
  end

  # Gets user's vote counts by post type
  # @return [Hash{Integer => Integer}]
  def votes_by_post_type
    votes.joins(:post).group(Arel.sql('posts.post_type_id')).count(Arel.sql('posts.post_type_id'))
  end
end
