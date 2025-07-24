module Timestamped
  extend ActiveSupport::Concern

  included do
    scope :newest_first, -> { reorder(created_at: :desc) }
    scope :oldest_first, -> { reorder(created_at: :asc) }
    scope :recent, ->(cutoff = 24.hours.ago) { where(created_at: cutoff..DateTime.now) }
  end
end
