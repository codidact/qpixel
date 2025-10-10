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
    # TODO send email
  end

  private

  def generate_access_token
    update(access_token: SecureRandom.uuid)
  end

  def assign_status
    update_status 'new'
  end
end
