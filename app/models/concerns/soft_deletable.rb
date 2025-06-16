module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :deleted, -> { where(deleted: true) }
    scope :undeleted, -> { where(deleted: false) }
  end
end
