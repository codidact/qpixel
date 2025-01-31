class UserWebsite < ApplicationRecord
  belongs_to :user
  default_scope { order(:position) }

  MAX_ROWS = 3
end
