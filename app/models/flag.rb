# Represents a flag. Flags are attached to both a user and a post, and have a single status.
class Flag < ApplicationRecord
  belongs_to :post
  belongs_to :user
  belongs_to :handled_by, class_name: 'User', required: false

  validates :reason, length: {minimum: 10, maximum: 1000}

  scope :handled, -> { where.not(status: nil) }
  scope :unhandled, -> { where(status: nil) }
end
