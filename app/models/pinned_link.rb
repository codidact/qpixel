class PinnedLink < ApplicationRecord
  include MaybeCommunityRelated

  belongs_to :post, optional: true

  scope :list_includes, lambda {
    includes(:post, post: [:community])
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
