class ModWarning < ApplicationRecord
  # Warning class name not accepted by Rails, hence this needed
  self.table_name = 'warnings'

  belongs_to :community_user

  def suspension_active?
    is_suspension && !suspension_end.past?
  end
end
