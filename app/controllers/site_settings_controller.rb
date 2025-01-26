# Web controller. Provides authenticated actions for use by administrators in controlling the site settings (which in
# turn control the operation and display of some aspects of the site).
class SiteSettingsController < ApplicationController
  before_action :verify_admin
  before_action :verify_global_admin, only: [:global]

  # Checks if a given user has access to site settings on a given community
  # @param [User] user user to check access for
  # @param [String, nil] community_id id of the community to check access on
  # @return [Boolean]
  def access?(user, community_id)
    community_id.present? || user.is_global_admin
  end

  def index
    # The weird argument to sort_by here sorts without throwing errors on nil values -
    # see https://stackoverflow.com/a/35539062/3160466. 0:1,c sorts nil last, to switch
    # round use 1:0,c
    @settings = SiteSetting.where(community_id: RequestContext.community_id).group_by(&:category)
                           .sort_by { |c, _ss| [c ? 0 : 1, c] }
  end

  def global
    @settings = SiteSetting.where(community_id: nil).group_by(&:category).sort_by { |c, _ss| [c ? 0 : 1, c] }
    render :index
  end

  def show
    @setting = if params[:community_id].present?
                 SiteSetting.applied_setting(params[:name])
               else
                 SiteSetting.global.where(name: params[:name]).priority_order.first
               end
    render json: @setting&.as_json&.merge(typed: @setting.typed)
  end

  # Adds an audit log for a given site setting update event
  # @param [User] user initiating user
  # @param [SiteSetting] before current site setting
  # @param [SiteSetting] after updated site setting
  # @return [void]
  def audit_update(user, before, after)
    AuditLog.admin_audit(event_type: 'setting_update',
                         related: after,
                         user: user,
                         comment: "from <<SiteSetting #{before}>>\nto <<SiteSetting #{after.attributes_print}>>")
  end

  # Deletes cache for a given site setting for a given community
  # @param [SiteSetting] setting site setting to clear cache for
  # @param [String, nil] community_id community id to clear cache for
  # @return [void]
  def clear_cache(setting, community_id)
    Rails.cache.delete("SiteSettings/#{community_id}/#{setting.name}", include_community: false)
  end

  def update
    unless access?(current_user, params[:community_id])
      not_found
      return
    end

    @setting = if params[:community_id].present?
                 matches = SiteSetting.unscoped.where(community_id: RequestContext.community_id, name: params[:name])
                 if matches.count.zero?
                   global = SiteSetting.unscoped.where(community_id: nil, name: params[:name]).first
                   SiteSetting.create(name: global.name, community_id: RequestContext.community_id, value: '',
                                      value_type: global.value_type, category: global.category,
                                      description: global.description)
                 else
                   matches.first
                 end
               else
                 SiteSetting.unscoped.where(community_id: nil, name: params[:name]).first
               end

    before = @setting.attributes_print

    @setting.update(setting_params)

    audit_update(current_user, before, @setting)

    clear_cache(@setting, RequestContext.community_id)

    render json: { status: 'OK', setting: @setting&.as_json&.merge(typed: @setting.typed) }
  end

  private

  def setting_params
    params.require(:site_setting).permit(:name, :value)
  end
end
