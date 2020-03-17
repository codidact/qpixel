# Represents a close reason. Close reasons can be assigned to posts

class CloseReason < ApplicationRecord
  scope :active, -> { where(active: true) }
end
