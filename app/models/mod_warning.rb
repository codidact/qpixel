class ModWarning < ApplicationRecord
  include Timestamped

  # Warning class name not accepted by Rails, hence this needed
  self.table_name = 'warnings'

  scope :global, -> { where(is_suspension: true, is_global: true) }

  belongs_to :community_user, optional: true
  belongs_to :user, optional: true
  belongs_to :author, class_name: 'User'

  scope :active, -> { where(active: true) }
  scope :to, ->(user) { where(community_user: user.community_user) }

  # Was the warning issued with a suspension?
  # @return [Boolean] check result
  def suspension?
    is_suspension
  end

  # Is the suspension issued with the warning still active?
  # @return [Boolean] check result
  def suspension_active?
    active && suspension? && !suspension_end.past?
  end

  def global_suspension?
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
