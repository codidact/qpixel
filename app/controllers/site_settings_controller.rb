class SiteSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin

  def index
    @settings = SiteSetting.all.paginate(:page => params[:page], :per_page => 20)
  end

  def edit
    @setting = SiteSetting.find params[:id]
  end

  def update
    @setting = SiteSetting.find params[:id]
    @setting.update(setting_params)
  end

  private
    def setting_params
      params.require(:site_setting).permit(:name, :value)
    end
end
