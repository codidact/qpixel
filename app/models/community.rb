class Community < ApplicationRecord
  has_many :community_users
  has_many :site_settings

  default_scope { where(is_fake: false) }

  validates :host, uniqueness: { case_sensitive: false }

  scope :user_preferred_order, lambda { |user|
    if user.nil?
      all
    else
      user_order = user.preference('community_order', community: false)
                       .split(',')
                       .map(&:to_i)

      # For some reason, even though we pass in filter: false,
      # if user_order is empty, in_order_of still returns an empty array.
      # Therefore we have to special case this
      if user_order.empty?
        all
      else
        in_order_of(:id, user_order, filter: false)
      end
    end
  }
end
