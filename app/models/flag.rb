# Represents a flag. Flags are attached to both a user and a post, and have a single status.
class Flag < ApplicationRecord
  belongs_to :post
  belongs_to :user

  has_one :flag_status

  validates :reason, length: { minimum: 10, maximum: 1000 }
end
