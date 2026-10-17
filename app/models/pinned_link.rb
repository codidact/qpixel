class PinnedLink < ApplicationRecord
  include MaybeCommunityRelated

  belongs_to :post, optional: true

  scope :list_includes, lambda {
    includes(:post, post: [:community])
  }

  scope :past, lambda {
    timed.where('shown_before < ?', DateTime.now)
  }

  scope :current, lambda {
    where(shown_after: nil, shown_before: nil).or(
      timed.where('shown_after is null or shown_after <= ?', DateTime.now)
           .where.not('shown_before < ?', DateTime.now)
    )
  }

  scope :future, lambda {
    timed.where('shown_after > ?', DateTime.now)
         .where('shown_before is null or shown_before >= ?', DateTime.now)
  }

  scope :timed, lambda {
    after = where.not(shown_after: nil)
    before = where.not(shown_before: nil)
    before.or(after)
  }

  validate :check_period
  validate :check_post_or_url

  # Creates an audit log for a pinned link create event
  # @param user [User] user that created the link
  # @param created [PinnedLink] created link
  def self.audit_create(user, created)
    attrs = created.attributes_print
    comment = "<<PinnedLink #{attrs}>>"

    AuditLog.moderator_audit(event_type: 'pinned_link_create',
                             related: created,
                             user: user,
                             comment: comment)
  end

  # Creates an audit log for a pinned link update event
  # @param user [User] user that updated the link
  # @param before [PinnedLink] state before the update
  # @param after [PinnedLink] state after the update
  def self.audit_update(user, before, after)
    old_attrs = before.attributes_print
    new_attrs = after.attributes_print
    comment = "from <<PinnedLink #{old_attrs}>>\nto <<PinnedLink #{new_attrs}>>"

    AuditLog.moderator_audit(event_type: 'pinned_link_update',
                             related: after,
                             user: user,
                             comment: comment)
  end

  # Is the link not timed or started in the past & hasn't ended yet?
  # @param now [DateTime, nil] timestamp to compare to
  # @return [Boolean] check result
  def current?(now = DateTime.now)
    !timed? || !(future?(now) || past?(now))
  end

  # Does the link start in the future?
  # @param now [DateTime, nil] timestamp to compare to
  # @return [Boolean] check result
  def future?(now = DateTime.now)
    shown_after.present? && shown_after > now && (shown_before.nil? || shown_before >= now)
  end

  # Has the link ended in the past?
  # @param now [DateTime, nil] timestamp to compare to
  # @return [Boolean] check result
  def past?(now = DateTime.now)
    shown_before.present? && shown_before < now
  end

  # Is the link time-constrained?
  # @return [Boolean] check result
  def timed?
    shown_before.present? || shown_after.present?
  end

  def check_period
    return unless shown_before.present? && shown_after.present?

    if shown_before < shown_after
      errors.add(:base, 'end date cannot be earlier than the start date')
    end
  end

  def check_post_or_url
    unless post_id.present? || link.present?
      errors.add(:base, 'either a post or a URL must be set')
    end
  end
end
