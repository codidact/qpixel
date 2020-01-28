# Web controller. Provides authenticated actions for use by administrators in controlling the site settings (which in
# turn control the operation and display of some aspects of the site).
class SiteSettingsController < ApplicationController
  before_action :verify_admin

  def index
    # The weird argument to sort_by here sorts without throwing errors on nil values -
    # see https://stackoverflow.com/a/35539062/3160466. 0:1,c sorts nil last, to switch
    # round use 1:0,c
    @settings = SiteSetting.all.group_by(&:category).sort_by { |c, _ss| [c ? 0 : 1, c] }
  end

  def show
    @setting = SiteSetting.find_by name: params[:name]
    render json: @setting&.as_json&.merge(typed: @setting.typed)
  end

  def update
    @setting = SiteSetting.find_by name: params[:name]
    @setting.update(setting_params)
    Rails.cache.delete "SiteSettings/#{@setting.name}"
    render json: {status: 'OK', setting: @setting&.as_json&.merge(typed: @setting.typed)}
  end

  private

  def setting_params
    params.require(:site_setting).permit(:name, :value)
  end
end