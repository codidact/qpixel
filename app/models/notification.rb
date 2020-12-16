class Notification < ApplicationRecord
  include CommunityRelated
  belongs_to :user

  delegate :name, to: :community, prefix: true
end
