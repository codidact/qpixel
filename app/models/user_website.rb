class UserWebsite < ApplicationRecord
  belongs_to :user
  default_scope { order(:position) }
end
