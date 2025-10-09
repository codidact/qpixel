class ComplaintComment < ApplicationRecord
  belongs_to :complaint
  belongs_to :user, required: false

  validates :content, presence: true
end
