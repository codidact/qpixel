class Notification < ApplicationRecord
  include CommunityRelated
  belongs_to :user

  def community_name
    community.name
  end
end
