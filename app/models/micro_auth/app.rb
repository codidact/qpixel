class MicroAuth::App < ApplicationRecord
  has_many :tokens, class_name: 'MicroAuth::Token'
  has_many :users, through: :tokens
  belongs_to :user
  belongs_to :deactivated_by, class_name: 'User', required: false

  validates :app_id, presence: true, uniqueness: { case_sensitive: false }
  validates :secret_key, presence: true, uniqueness: { case_sensitive: false }
  validates :public_key, presence: true, uniqueness: { case_sensitive: false }

  def valid_redirect?(redirect_uri)
    valid_domain = URI(auth_domain.start_with?('http') ? auth_domain : "http://#{auth_domain}").hostname
    redirect_domain = URI(redirect_uri).hostname
    redirect_domain.end_with? valid_domain
  rescue URI::InvalidURIError
    false
  end
end
