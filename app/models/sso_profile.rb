class SsoProfile < ApplicationRecord
  belongs_to :user, inverse_of: :sso_profile

  validates :saml_identifier, uniqueness: true, presence: true
end
