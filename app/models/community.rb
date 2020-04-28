class Community < ApplicationRecord
  has_many :community_users

  validates :host, uniqueness: true
end
