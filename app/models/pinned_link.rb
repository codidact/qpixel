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

  validate :check_post_or_url

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

  def check_post_or_url
    unless post_id.present? || link.present?
      errors.add(:base, 'either a post or a URL must be set')
    end
  end
end
