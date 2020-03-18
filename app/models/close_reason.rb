# Represents a close reason. Close reasons can be assigned to posts

class CloseReason < ApplicationRecord
  belongs_to :community
  scope :active, ->(community_id) { where(active: true, community_id: nil) + where(active: true, community_id: community_id) }
end
