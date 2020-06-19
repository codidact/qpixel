class ModWarning < ApplicationRecord
  # Warning class name not accepted by Rails, hence this needed
  self.table_name = 'warnings'

  belongs_to :community_user
  belongs_to :author, class_name: 'User'

  def suspension_active?
    is_suspension && !suspension_end.past?
  end

  def body_as_html
    helpers.render_markdown(body)
  end
end
