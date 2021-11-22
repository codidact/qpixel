class MicroAuth::Token < ApplicationRecord
  belongs_to :app, class_name: 'MicroAuth::App'
  belongs_to :user

  serialize :scope, JSON

  scope :active, -> { where('expires_at > ?', DateTime.now) }

  def active?
    expires_at.nil? || expires_at.future?
  end
end
