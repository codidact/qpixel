class UserWebsite < ApplicationRecord
  belongs_to :user
  default_scope { order(:position) }

  MaxRows = 3
end
