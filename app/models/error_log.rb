class ErrorLog < ApplicationRecord
  belongs_to :community, required: false
  belongs_to :user, required: false
end
