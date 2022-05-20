class ModWarning < ApplicationRecord
  # Warning class name not accepted by Rails, hence this needed
  self.table_name = 'warnings'

  scope :global, -> { where(is_suspension: true, is_global: true) }

  belongs_to :community_user, optional: true
  belongs_to :user, optional: true
  belongs_to :author, class_name: 'User'

  def suspension_active?
    active && is_suspension && !suspension_end.past?
  end

  def global?
    is_suspension && is_global
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
