# Represents a flag. Flags are attached to both a user and a post, and have a single status.
class Flag < ApplicationRecord
  include PostRelated
  belongs_to :user
  belongs_to :handled_by, class_name: 'User', optional: true
  belongs_to :post_flag_type

  scope :handled, -> { where.not(status: nil) }
  scope :unhandled, -> { where(status: nil) }

  scope :confidential, -> { where(post_flag_type: PostFlagType.confidential).or(where(post_flag_type: nil)) }
  scope :not_confidential, -> { where(post_flag_type: PostFlagType.not_confidential) }
end
