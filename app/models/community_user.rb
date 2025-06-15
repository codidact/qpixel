class CommunityUser < ApplicationRecord
  belongs_to :community
  belongs_to :user

  has_many :mod_warnings, dependent: :nullify
  has_many :user_abilities, dependent: :destroy
  belongs_to :deleted_by, required: false, class_name: 'User'

  validates :user_id, uniqueness: { scope: [:community_id], case_sensitive: false }

  scope :for_context, -> { where(community_id: RequestContext.community_id) }
  scope :active, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }

  after_create :prevent_ulysses_case

  delegate :url_helpers, to: 'Rails.application.routes'

  def system?
    user_id == -1
  end

  def suspended?
    return true if is_suspended && !suspension_end.past?

    if is_suspended
      update(is_suspended: false, suspension_public_comment: nil, suspension_end: nil)
    end

    false
  end

  def latest_warning
    mod_warnings&.order(created_at: 'desc')&.first&.created_at
  end

  # Calculation functions for privilege scores
  # These are quite expensive, so we'll cache them for a while
  def post_score
    Rails.cache.fetch("privileges/#{id}/post_score", expires_in: 3.hours) do
      exclude_types = ApplicationController.helpers.post_type_ids(is_freely_editable: true)
      good_posts = Post.where(user: user).where('score > 0.5').where.not(post_type_id: exclude_types).count
      bad_posts = Post.where(user: user).where('score < 0.5').where.not(post_type_id: exclude_types).count

      (good_posts + 2.0) / (good_posts + bad_posts + 4.0)
    end
  end

  def edit_score
    Rails.cache.fetch("privileges/#{id}/edit_score", expires_in: 3.hours) do
      good_edits = SuggestedEdit.by(user).approved.count
      bad_edits = SuggestedEdit.by(user).rejected.count

      (good_edits + 2.0) / (good_edits + bad_edits + 4.0)
    end
  end

  def flag_score
    Rails.cache.fetch("privileges/#{id}/flag_score", expires_in: 3.hours) do
      good_flags = Flag.by(user).helpful.count
      bad_flags = Flag.by(user).declined.count

      (good_flags + 2.0) / (good_flags + bad_flags + 4.0)
    end
  end

  # Checks if the community user has a given ability
  # @param internal_id [String] The +internal_id+ of the ability to check
  # @return [Boolean] check result
  def privilege?(internal_id, ignore_suspension: false, ignore_mod: false)
    if internal_id != 'mod' && !ignore_mod && user.at_least_moderator?
      return true # includes: privilege? 'mod'
    end

    up = privilege(internal_id)
    if ignore_suspension
      !up.nil?
    else
      !up.nil? && !up.suspended?
    end
  end

  def privilege(internal_id)
    UserAbility.joins(:ability).where(community_user_id: id, abilities: { internal_id: internal_id }).first
  end

  ##
  # Grant a specified ability to this CommunityUser.
  # @param internal_id [String] The +internal_id+ of the ability to grant.
  # @param notify [Boolean] Whether to send a notification to the user.
  def grant_privilege!(internal_id, notify: true)
    priv = Ability.where(internal_id: internal_id).first
    UserAbility.create community_user_id: id, ability: priv
    if notify
      community_host = priv.community.host
      user.create_notification("You've earned the #{priv.name} ability! Learn more.",
                               url_helpers.ability_url(priv.internal_id, host: community_host))
    end
  end

  ##
  # Recalculate a specified ability for this CommunityUser. Will not revoke abilities that have already been granted.
  # @param internal_id [String] The +internal_id+ of the ability to be recalculated.
  # @param sandbox [Boolean] Whether to run in sandbox mode - if sandboxed, the ability will not be granted but the
  #   return value indicates whether it would have been.
  # @return [Boolean] Whether or not the ability was granted.
  def recalc_privilege(internal_id, sandbox: false)
    # Do not recalculate privileges already granted
    return true if privilege?(internal_id, ignore_suspension: true, ignore_mod: false)

    priv = Ability.where(internal_id: internal_id).first

    # Do not recalculate privileges which are only manually given
    return false if priv.manual?

    # Grant :unrestricted automatically on new communities
    unless SiteSetting['NewSiteMode'] && internal_id.to_s == 'unrestricted'
      # Abort if any of the checks fails
      return false if !priv.post_score_threshold.nil? && post_score < priv.post_score_threshold
      return false if !priv.edit_score_threshold.nil? && edit_score < priv.edit_score_threshold
      return false if !priv.flag_score_threshold.nil? && flag_score < priv.flag_score_threshold
    end

    # If not sandbox mode, create new privilege entry
    grant_privilege!(internal_id) unless sandbox
    recalc_trust_level unless sandbox
    true
  end

  ##
  # Recalculate a list of standard abilities for this CommunityUser.
  # @param sandbox [Boolean] Whether to run in sandbox mode - see {#recalc_privilege}.
  # @return [Array<Boolean>]
  def recalc_privileges(sandbox: false)
    [:everyone, :unrestricted, :edit_posts, :edit_tags, :flag_close, :flag_curate].map do |ability|
      recalc_privilege(ability, sandbox: sandbox)
    end
  end

  alias ability? privilege?
  alias ability privilege
  alias grant_ability! grant_privilege!
  alias recalc_ability recalc_privilege
  alias recalc_abilities recalc_privileges

  # This check makes sure that every user gets the
  # 'everyone' permission upon creation. We do not want
  # to create a no permissions user by accident.
  # Polyphemus is very grateful for this.
  def prevent_ulysses_case
    recalc_privileges
  end

  def trust_level
    attributes['trust_level'] || recalc_trust_level
  end

  # Checks if the community user is an admin (global or on the current community)
  # @return [Boolean] check result
  def admin?
    is_admin || user&.global_admin? || false
  end

  # Checks if the community user is a moderator (global or on the current community)
  # @return [Boolean] check result
  def moderator?
    is_moderator || user&.global_moderator? || false
  end

  # Checks if the community user is a moderator or has higher access (global or on the current community)
  # @return [Boolean] check result
  def at_least_moderator?
    moderator? || admin?
  end

  def recalc_trust_level
    trust = if user.staff?
              5
            elsif at_least_moderator?
              4
            elsif privilege?('flag_close') || privilege?('edit_posts')
              3
            elsif privilege?('unrestricted')
              2
            else
              1
            end
    update(trust_level: trust)
    trust
  end
end
