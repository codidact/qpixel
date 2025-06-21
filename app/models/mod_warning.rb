class ModWarning < ApplicationRecord
  # Warning class name not accepted by Rails, hence this needed
  self.table_name = 'warnings'

  belongs_to :community_user
  belongs_to :author, class_name: 'User'

  scope :active, -> { where(active: true) }
  scope :to, ->(user) { where(community_user: user.community_user) }

  def suspension_active?
    active && is_suspension && !suspension_end.past?
  end

  def body_as_html
    ApplicationController.helpers.render_markdown(body)
  end

  # These two are necessary for the new warning form to work.
  def suspension_duration
    1
  end

  def suspension_public_notice
    nil
  end
end
