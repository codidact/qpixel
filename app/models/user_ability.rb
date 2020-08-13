class UserAbility < ApplicationRecord
  belongs_to :community_user
  belongs_to :ability

  def suspended?
    return true if is_suspended && suspension_end.nil? # permanent suspension
    return true if is_suspended && !suspension_end.past?

    if is_suspended
      update(is_suspended: false, suspension_message: nil, suspension_end: nil)
    end

    false
  end
end
