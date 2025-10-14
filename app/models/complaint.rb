class Complaint < ApplicationRecord
  belongs_to :user, required: false
  belongs_to :assignee, required: false, class_name: 'User'
  has_many :comments, class_name: 'ComplaintComment', dependent: :destroy

  after_create :generate_access_token
  after_create :assign_status

  validates :email, presence: -> { !user.present? }
  validates :report_type, presence: true
  validates :reported_url, presence: true

  ##
  # Update the complaint's status, create a comment to record the change, and send emails to the right people.
  # @param new_status [String] The new status to set, from safety_center.yml.
  # @param attribute_to [String] Who should the status change be attributed to? Username only.
  def update_status(new_status, attribute_to = nil)
    dt = DateTime.now
    update(status: new_status, status_updated_at: dt)
    attribution = attribute_to.nil? ? 'automatically' : "by #{attribute_to}"
    comments.create(content: "Status updated to #{new_status} at #{dt.iso8601} #{attribution}.", internal: true,
                    user_id: -1)
    # TODO: send email
  end

  ##
  # Can a specified user currently add more comments to this complaint?
  # @param user [User, nil] The user to check.
  # @return [Boolean] check result
  def can_add_more_comments?(user)
    # If the current user is staff, the last user is irrelevant - don't query.
    last_user_id = user&.staff? ? nil : comments.external.last&.user_id

    # Reporters may only add one reply between staff responses, so can_add_more is true if current_user is staff
    # or if the last comment's user ID is not nil and not equal to the current user ID, and the report is open.
    user&.staff? || (last_user_id.nil? && last_user_id != user&.id && status != 'closed')
  end

  private

  def generate_access_token
    update(access_token: SecureRandom.uuid)
  end

  def assign_status
    update_status 'new'
  end
end
