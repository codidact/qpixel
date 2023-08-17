class ActiveStorage::BaseController < ActionController::Base
  before_action :enforce_signed_in
  include ActiveStorage::SetCurrent
  protect_from_forgery with: :exception

  self.etag_with_template_digest = false

  protected

  def enforce_signed_in
    # If not restricted, the user is signed in or the environment is test, allow all content.
    return true if !SiteSetting['RestrictedAccess'] || user_signed_in? || Rails.env.test?

    redirect_to '/', status: :forbidden
    false
  end
end
