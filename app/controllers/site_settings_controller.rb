class SiteSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin

  # Authenticated administrator web action. Retrieves a paginated list of all site settings.
  def index
    @settings = SiteSetting.all.paginate(:page => params[:page], :per_page => 20)
  end

  # Authenticated administrator web action. Retrieves a single site setting for editing.
  def edit
    @setting = SiteSetting.find params[:id]
  end

  # Authenticated administrator web action. Applies new values submitted by the user to a single site setting. Redirects
  # on completion back to the <tt>index</tt> action.
  def update
    @setting = SiteSetting.find params[:id]
    @setting.update(setting_params)
    redirect_to url_for(:controller => :site_settings, :action => :index)
  end

  private
    # Sanitizes parameters for use in updates of site settings. You'd expect that administrators could be trusted not to
    # deliberately try to break things, but there's always the possibility that they get their accounts hijacked.
    def setting_params
      params.require(:site_setting).permit(:name, :value)
    end
end
