class CommunityUser < ApplicationRecord
  belongs_to :community
  belongs_to :user

  has_many :mod_warnings, dependent: :nullify

  validates :user_id, uniqueness: { scope: [:community_id] }

  scope :for_context, -> { where(community_id: RequestContext.community_id) }

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
    Rails.cache.fetch("privileges/#{id}/post_score", expires_in: 2.hours) do
      good_posts = Post.where(user: user).where('score > 0.5').count
      bad_posts = Post.where(user: user).where('score < 0.5').count

      (good_posts + 1.0) / (good_posts + bad_posts + 2.0)
    end
  end

  def edit_score
    Rails.cache.fetch("privileges/#{id}/edit_score", expires_in: 2.hours) do
      good_edits = SuggestedEdit.where(user: user).where(active: false, accepted: true).count
      bad_edits = SuggestedEdit.where(user: user).where(active: false, accepted: false).count

      (good_edits + 1.0) / (good_edits + bad_edits + 2.0)
    end
  end

  def flag_score
    Rails.cache.fetch("privileges/#{id}/flag_score", expires_in: 2.hours) do
      good_flags = Flag.where(user: user).where(status: 'helpful').count
      bad_flags = Flag.where(user: user).where(status: 'declined').count

      (good_flags + 1.0) / (good_flags + bad_flags + 2.0)
    end
  end

  def privilege?(internal_id, ignore_suspension: false)
    priv = TrustLevel.where(internal_id: internal_id).first
    if ignore_suspension
      UserPrivilege.where(community_user_id: id, trust_level: priv).any?
    else
      UserPrivilege.where(community_user_id: id, trust_level: priv, is_suspended: false).any
    end
  end

  def privilege(internal_id)
    priv = TrustLevel.where(internal_id: internal_id).first
    UserPrivilege.where(community_user_id: id, trust_level: priv).first
  end

  def grant_privilege(internal_id)
    priv = TrustLevel.where(internal_id: internal_id).first
    UserPrivilege.create community_user_id: id, trust_level: priv
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def recalc_privilege(internal_id, sandbox: false)
    # Do not recalculate privileges already granted
    return true if privilege?(internal_id, ignore_suspension: true)

    priv = TrustLevel.where(internal_id: internal_id).first

    # Do not recalculate privileges which are only manually given
    return false if priv.post_score_threshold.nil? && \
                    priv.edit_score_threshold.nil? && \
                    priv.flag_score_threshold.nil?

    # Abort if any of the checks fails
    return false if !priv.post_score_threshold.nil? && post_score < priv.post_score_threshold
    return false if !priv.edit_score_threshold.nil? && edit_score < priv.edit_score_threshold
    return false if !priv.flag_score_threshold.nil? && flag_score < priv.flag_score_threshold

    # If not sandbox mode, create new privilege entry
    grant_privilege(internal_id) unless sandbox

    true
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def recalc_privileges(sandbox: false)
    recalc_privilege('unrestricted', sandbox) unless privilege?('unrestricted', ignore_suspension: true)
    recalc_privilege('edit_posts', sandbox) unless privilege?('edit_posts', ignore_suspension: true)
    recalc_privilege('edit_tags', sandbox) unless privilege?('edit_tags', ignore_suspension: true)
    recalc_privilege('flag_close', sandbox) unless privilege?('flag_close', ignore_suspension: true)
    recalc_privilege('flag_curate', sandbox) unless privilege?('flag_curate', ignore_suspension: true)
  end
end
