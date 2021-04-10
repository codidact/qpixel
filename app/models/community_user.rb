class CommunityUser < ApplicationRecord
  belongs_to :community
  belongs_to :user

  has_many :mod_warnings, dependent: :nullify
  has_many :user_abilities, dependent: :destroy

  validates :user_id, uniqueness: { scope: [:community_id] }

  scope :for_context, -> { where(community_id: RequestContext.community_id) }

  after_create :prevent_ulysses_case

  def suspended?
    return true if is_suspended && !suspension_end.past?

    if is_suspended
      update(is_suspended: false, suspension_public_comment: nil, suspension_end: nil)
    end

    false
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
      good_edits = SuggestedEdit.where(user: user).where(active: false, accepted: true).count
      bad_edits = SuggestedEdit.where(user: user).where(active: false, accepted: false).count

      (good_edits + 2.0) / (good_edits + bad_edits + 4.0)
    end
  end

  def flag_score
    Rails.cache.fetch("privileges/#{id}/flag_score", expires_in: 3.hours) do
      good_flags = Flag.where(user: user).where(status: 'helpful').count
      bad_flags = Flag.where(user: user).where(status: 'declined').count

      (good_flags + 2.0) / (good_flags + bad_flags + 4.0)
    end
  end

  ## Privilege functions

  def privilege?(internal_id, ignore_suspension: false, ignore_mod: false)
    if (internal_id != 'mod' || ignore_mod) && user.is_moderator
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

  def grant_privilege(internal_id)
    priv = Ability.where(internal_id: internal_id).first
    UserAbility.create community_user_id: id, ability: priv
  end

  def recalc_privilege(internal_id, sandbox: false)
    # Do not recalculate privileges already granted
    return true if privilege?(internal_id, ignore_suspension: true, ignore_mod: true)

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
    grant_privilege(internal_id) unless sandbox
    recalc_trust_level unless sandbox
    true
  end

  def recalc_privileges(sandbox: false)
    [:everyone, :unrestricted, :edit_posts, :edit_tags, :flag_close, :flag_curate].map do |ability|
      recalc_privilege(ability, sandbox: sandbox)
    end
  end

  # This check makes sure, that every user gets the
  # everyone permission upon creation. We do not want
  # to create a noone by accident.
  # Polyphemus is very grateful for this.
  def prevent_ulysses_case
    recalc_privileges
  end

  def trust_level
    attributes['trust_level'] || recalc_trust_level
  end

  def recalc_trust_level
    trust = if user.staff?
              5
            elsif is_moderator || user.is_global_moderator || is_admin || user.is_global_admin
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
