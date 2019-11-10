# Web controller. Provides authenticated actions for use by administrators in controlling the site settings (which in
# turn control the operation and display of some aspects of the site).
class SiteSettingsController < ApplicationController
  before_action :verify_admin

  # Authenticated administrator web action. Retrieves a paginated list of all site settings.
  def index
    @settings = SiteSetting.all.paginate(page: params[:page], per_page: 20)
  end

  # Authenticated administrator web action. Retrieves a single site setting for editing.
  def edit
    @setting = SiteSetting.find params[:id]
  end

  # Authenticated administrator web action. Applies new values submitted by the user to a single site setting. Redirects
  # on completion back to the <tt>index</tt> action.
  def update
    requires_sanitization = ['AskingGuidance', 'AnsweringGuidance']
    @setting = SiteSetting.find params[:id]
    @setting.update(setting_params)
    if requires_sanitization.include?(@setting.name)
      @setting.value = ActionController::Base.helpers.sanitize(@setting.value, scrubber: SiteSettingScrubber.new)
      @setting.save!
    end
    redirect_to url_for(controller: :site_settings, action: :index)
  end

  private
    # Sanitizes parameters for use in updates of site settings. You'd expect that administrators could be trusted not to
    # deliberately try to break things, but there's always the possibility that they get their accounts hijacked.
    def setting_params
      params.require(:site_setting).permit(:name, :value)
    end
end

# Provides a custom HTML sanitization interface to use for cleaning up the HTML in site settings.
class SiteSettingScrubber < Rails::Html::PermitScrubber
  # Sets up the scrubber instance with permissible tags and attributes.
  def initialize
    super
    self.tags = %w( p b i em strong ul ol li a )
    self.attributes = %w( href title )
  end

  # Defines which nodes should be skipped when sanitizing HTML.
  def skip_node?(node)
    node.text?
  end
end
