class Notification < ApplicationRecord
  include CommunityRelated

  belongs_to :user

  delegate :name, to: :community, prefix: true

  # Is the notification marked as read?
  # @return [Boolean] check result
  def read?
    is_read
  end

  # Is the notification not marked as read? The inverse of +read?+
  # @return [Boolean] check result
  def unread?
    !read?
  end

  def rendered_timestamp
    formatted = created_at.strftime('%b&nbsp;%-d,&nbsp;%Y&nbsp;at&nbsp;%H:%M')
    CGI.unescape_html(formatted).html_safe
  end
end
