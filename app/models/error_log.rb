class ErrorLog < ApplicationRecord
  belongs_to :community, optional: true
  belongs_to :user, optional: true
end
