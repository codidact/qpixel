# Represents a flag. Flags are attached to both a user and a post, and have a single status.
class Flag < ApplicationRecord
  include CommunityRelated
  include Timestamped
  include Routing

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

  ##
  # Resolve a flag and run associated ability and notification actions.
  # @param status [String, ActionController::Parameters] new status of the flag
  # @param message [String, ActionController::Parameters] custom response to the flag
  # @param handled_by [User] user who handled the flag
  # @param handled_at [DateTime, nil] time the flag was handled (defaults to current time)
  # @return [Boolean] result
  def resolve(status:, message:, handled_by:, handled_at: nil)
    status = false

    transaction do
      status = update(status: status,
                      message: message,
                      handled_by: handled_by,
                      handled_at: handled_at || DateTime.now)

      status = status && AbilityQueue.add(user, "Flag Handled ##{id}")

      unless status
        raise ActiveRecord::Rollback
      end

      unless message.blank?
        # TODO: create_notification actually behaves like a bang method
        user.create_notification('A moderator has written a response to your flag. Check your flag history page.',
                                 flag_history_url(user))
      end
    end

    status
  end
end
