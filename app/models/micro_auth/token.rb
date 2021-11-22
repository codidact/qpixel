class MicroAuth::Token < ApplicationRecord
  belongs_to :app, class_name: 'MicroAuth::App'
  belongs_to :user

  scope :active, -> { where('expires_at > ?', DateTime.now) }

  def active?
    expires_at.future?
  end
end
