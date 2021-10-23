class Community < ApplicationRecord
  has_many :community_users
  has_many :site_settings

  default_scope { where(is_fake: false) }

  validates :host, uniqueness: true
end
