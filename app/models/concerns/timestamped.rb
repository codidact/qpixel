module Timestamped
  extend ActiveSupport::Concern

  included do
    scope :newest_first, -> { reorder(created_at: :desc) }
    scope :oldest_first, -> { reorder(created_at: :asc) }
    scope :recent, -> { where(created_at: 24.hours.ago..DateTime.now) }
  end
end
