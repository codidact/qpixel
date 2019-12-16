# Provides helper methods for use by views under <tt>ApplicationController</tt> (and by extension, every view).
module ApplicationHelper
  def user_is_mod
    user_signed_in? && (current_user.is_moderator || current_user.is_admin)
  end

  def user_is_admin
    user_signed_in? && current_user.is_admin
  end

  def check_your_post_privilege(post, privilege)
    current_user&.has_post_privilege?(privilege, post)
  end

  def check_your_privilege(privilege)
    current_user&.has_privilege?(privilege)
  end

  def query_url(**params)
    uri = URI.parse(request.original_url)
    query = Rack::Utils.parse_nested_query uri.query
    query = query.merge(params.map { |k, v| [k.to_s, v.to_s] }.to_h)
    uri.query = query.map { |k, v| "#{k}=#{v}" }.join('&')
    uri.to_s
  end

  def license_link
    link_to SiteSetting['ContentLicenseName'], SiteSetting['ContentLicenseLink']
  end
end
