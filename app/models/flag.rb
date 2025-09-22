# Represents a flag. Flags are attached to both a user and a post, and have a single status.
class Flag < ApplicationRecord
  include CommunityRelated
  include Timestamped

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

  scope :escalated, -> { where(escalated: true) }

  validate :maximum_reason_length

  # Gets flags appropriately scoped for a given user & post
  # @param user [User, nil] user to check
  # @param post [Post] post to check
  # @return [ActiveRecord::Relation<Flag>]
  def self.accessible_to(user, post)
    if user&.at_least_moderator?
      post.flags
    elsif user&.can_handle_flags?
      post.flags.not_confidential
    else
      post.flags.none
    end
  end

  # Checks if the flag is confidential as per its type
  # @return [Boolean] check result
  def confidential?
    post_flag_type&.confidential || false
  end

  def maximum_reason_length
    max_len = SiteSetting['MaxFlagReasonLength'] || 1000
    if reason.length > [max_len, 1000].min
      errors.add(:reason, "can't be more than #{max_len} characters")
    end
  end
end
