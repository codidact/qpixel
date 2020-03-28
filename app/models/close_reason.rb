# Represents a close reason. Close reasons can be assigned to posts

class CloseReason < ApplicationRecord
  include MaybeCommunityRelated
end
