class PinnedLink < ApplicationRecord
  include MaybeCommunityRelated

  belongs_to :post, optional: true

  scope :list_includes, lambda {
    includes(:post, post: [:community])
  }

  # a past link is one that ended in the past
  scope :past, lambda {
    timed.where('shown_before < ?', DateTime.now)
  }

  # a present link is not timed or started in the past and ends in the future
  scope :present, lambda {
    where(shown_after: nil, shown_before: nil).or(
      timed.where('shown_after <= ?', DateTime.now)
           .where('shown_before > ?', DateTime.now)
    )
  }

  # a future link is one that both starts and ends in the future
  scope :future, lambda {
    timed.where('shown_after > ?', DateTime.now)
         .where('shown_before > ?', DateTime.now)
  }

  scope :timed, lambda {
    after = where.not(shown_after: nil)
    before = where.not(shown_before: nil)
    before.or(after)
  }

  validate :check_post_or_url

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
