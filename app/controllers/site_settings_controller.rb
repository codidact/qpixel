# Web controller. Provides authenticated actions for use by administrators in controlling the site settings (which in
# turn control the operation and display of some aspects of the site).
class SiteSettingsController < ApplicationController
  before_action :verify_admin

  def index
    @settings = SiteSetting.all.paginate(page: params[:page], per_page: 20).order(name: :asc)
  end

  def show
    @setting = SiteSetting.find_by name: params[:name]
    render json: @setting&.as_json&.merge(typed: @setting.typed)
  end

  def update
    @setting = SiteSetting.find_by name: params[:name]
    @setting.update(setting_params)
    render json: {status: 'OK', setting: @setting&.as_json&.merge(typed: @setting.typed)}
  end

  private

  def setting_params
    params.require(:site_setting).permit(:name, :value)
  end
end

# Provides a custom HTML sanitization interface to use for cleaning up the HTML in site settings.
class SiteSettingScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w( p b i em strong ul ol li a )
    self.attributes = %w( href title )
  end

  def skip_node?(node)
    node.text?
  end
end
