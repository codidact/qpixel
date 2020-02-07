class Notification < ApplicationRecord
  include CommunityRelated
  belongs_to :user
end
