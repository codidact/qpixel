# Represents a flag. Flags are attached to both a user and a post, and have a single status.
class Flag < ApplicationRecord
  include CommunityRelated
  belongs_to :post, polymorphic: true
  belongs_to :user
  belongs_to :handled_by, class_name: 'User', optional: true
  belongs_to :post_flag_type, optional: true
  belongs_to :escalated_by, class_name: 'User', optional: true

  scope :by, ->(user) { where(user: user) }
  scope :declined, -> { where(status: 'declined') }
  scope :helpful, -> { where(status: 'helpful') }

  scope :handled, -> { where.not(status: nil) }
  scope :unhandled, -> { where(status: nil) }

  scope :confidential, -> { where(post_flag_type: PostFlagType.confidential).or(where(post_flag_type: nil)) }
  scope :not_confidential, -> { where(post_flag_type: PostFlagType.not_confidential) }

  # Checks if the flag is confidential as per its type
  # @return [Boolean] check result
  def confidential?
    post_flag_type&.confidential || false
  end
end
