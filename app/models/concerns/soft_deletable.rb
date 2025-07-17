module SoftDeletable
  extend ActiveSupport::Concern

  included do
    belongs_to :deleted_by, class_name: 'User', optional: true

    scope :deleted, -> { where(deleted: true) }
    scope :undeleted, -> { where(deleted: false) }
  end
end
