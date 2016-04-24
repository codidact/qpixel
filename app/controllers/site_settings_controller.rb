class SiteSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin
end
