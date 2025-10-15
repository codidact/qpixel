class Complaint < ApplicationRecord
  belongs_to :user, required: false
  belongs_to :assignee, required: false, class_name: 'User'
  has_many :comments, class_name: 'ComplaintComment', dependent: :destroy

  after_create :generate_access_token
  after_create :assign_status
  after_create :send_receipt_email
  after_update :send_reviewed_email

  validates :email, presence: -> { !user.present? }
  validates :report_type, presence: true
  validates :reported_url, presence: true

  scope :active, -> { where(status: ['new', 'assigned', 'responded']) }
  scope :closed, -> { where(status: 'closed') }
  scope :reviewed, -> { where(status: 'reviewed') }

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
  end

  ##
  # Can a specified user currently add more comments to this complaint?
  # @param user [User, nil] The user to check.
  # @return [Boolean] check result
  def can_add_more_comments?(user)
    if user&.staff? || comments.external.empty?
      true
    else
      last_user_id = comments.external.most_recent&.user_id
      last_user_id != user&.id && status != 'closed'
    end
  end

  private

  def generate_access_token
    update(access_token: SecureRandom.uuid)
  end

  def assign_status
    update_status 'new'
  end

  def send_receipt_email
    ComplaintsMailer.with(complaint: self).new_complaint.deliver_later
  end

  def send_reviewed_email
    if status == 'reviewed' && !outcome.nil? && user_wants_updates?
      ComplaintsMailer.with(complaint: self).complaint_reviewed.deliver_later
    end
  end
end
