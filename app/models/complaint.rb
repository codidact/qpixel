class Complaint < ApplicationRecord
  belongs_to :user, required: false
  belongs_to :assignee, required: false, class_name: 'User'

  after_create :generate_access_token

  private

  def generate_access_token
    update(access_token: SecureRandom.uuid)
  end
end
