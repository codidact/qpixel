class Community < ApplicationRecord
  has_many :community_users

  default_scope { where(is_fake: false) }

  validates :host, uniqueness: true
end
