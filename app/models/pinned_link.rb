class PinnedLink < ApplicationRecord
  include MaybeCommunityRelated
  belongs_to :post

  # Is the link time-constrained?
  # @return [Boolean] check result
  def timed?
    shown_before.present? || shown_after.present?
  end
end
