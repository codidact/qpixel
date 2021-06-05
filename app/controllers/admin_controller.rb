# Web controller. Provides authenticated actions for use by administrators.
class AdminController < ApplicationController
  before_action :verify_admin, except: [:change_back, :verify_elevation]
  before_action :verify_global_admin, only: [:admin_email, :send_admin_email, :new_site, :create_site, :setup,
                                             :setup_save, :hellban]
  before_action :verify_developer, only: [:change_users, :impersonate]

  def index; end

  def error_reports
    @reports = if params[:uuid].present?
                 ErrorLog.where(uuid: params[:uuid])
               elsif current_user.is_global_admin
                 ErrorLog.all
               else
                 ErrorLog.where(community: RequestContext.community)
               end.order(created_at: :desc).paginate(page: params[:page], per_page: 50)
  end

  def privileges
    @abilities = Ability.all
  end

  def show_privilege
    @ability = Ability.find_by internal_id: params[:name]
    respond_to do |format|
      format.json { render json: @ability }
    end
  end

  def update_privilege
    @ability = Ability.find_by internal_id: params[:name]
    type = ['post', 'edit', 'flag'].include?(params[:type]) ? params[:type] : nil
    return not_found if type.nil?

    pre = @ability.send("#{type}_score_threshold".to_sym)
    @ability.update("#{type}_score_threshold" => params[:threshold])
    AuditLog.admin_audit(event_type: 'ability_threshold_update', related: @ability, user: current_user,
                         comment: "#{params[:type]} score\nfrom <<#{pre}>>\nto <<#{params[:threshold]}>>")
    render json: { status: 'OK', privilege: @ability }, status: :accepted
  end

  def admin_email; end

  def send_admin_email
    Thread.new do
      AdminMailer.with(body_markdown: params[:body_markdown], subject: params[:subject]).to_moderators.deliver_now
    end
    AuditLog.admin_audit(event_type: 'send_admin_email', user: current_user,
                         comment: "Subject: #{params[:subject]}")
    flash[:success] = t 'admin.email_being_sent'
    redirect_to admin_path
  end

  def audit_log
    @logs = if current_user.is_global_admin
              AuditLog.unscoped.where.not(log_type: ['user_annotation', 'user_history'])
            else
              AuditLog.where.not(log_type: ['block_log', 'user_annotation', 'user_history'])
            end.user_sort({ term: params[:sort], default: :created_at },
                          age: :created_at, type: :log_type, event: :event_type,
                          related: Arel.sql('related_type DESC, related_id DESC'), user: :user_id)
            .paginate(page: params[:page], per_page: 100)
    render layout: 'without_sidebar'
  end

  def new_site
    @new_community = Community.new
  end

  def create_site
    @new_community = Community.create(name: params[:community][:name], host: params[:community][:host])

    # Run Seeds
    Rails.application.load_seed

    # Manage Site Settings
    settings = SiteSetting.for_community_id(@new_community.id)
    settings.find_by(name: 'SiteName').update(value: @new_community.name)

    # Audit Log
    AuditLog.admin_audit(event_type: 'new_site', related: @new_community, user: current_user,
                         comment: "<<Community #{@new_community.attributes_print}>>")

    # Clear cache
    Rails.cache.clear

    # Render template
    render
  end

  def setup; end

  def setup_save
    settings = SiteSetting.for_community_id(@community.id)
    default_settings = SiteSetting.for_community_id(Community.first.id)

    # Set settings from config page
    { primary_color: 'SiteCategoryHeaderDefaultColor', logo_url: 'SiteLogoPath', ad_slogan: 'SiteAdSlogan',
      mathjax: 'MathJaxEnabled', syntax_highlighting: 'SyntaxHighlightingEnabled', chat_link: 'ChatLink',
      analytics_url: 'AnalyticsURL', analytics_id: 'AnalyticsSiteId', content_transfer: 'AllowContentTransfer' } \
      .each do |key, setting|
      settings.find_by(name: setting).update(value: params[key])
    end

    # Auto-load settings
    ['AdminBadgeCharacter', 'ModBadgeCharacter', 'SEApiClientId', 'SEApiClientSecret', 'SEApiKey',
     'AdministratorContactEmail'].each do |setting|
      settings.find_by(name: setting)
              .update(value: default_settings.find_by(name: setting).value)
    end

    # Generate meta tags
    required_tags = ['discussion', 'support', 'feature-request', 'bug']
    status_tags = ['status-completed', 'status-declined', 'status-review', 'status-planned', 'status-deferred']
    tags = required_tags + status_tags
    Tag.create(tags.map { |t| { name: t, community_id: @community.id, tag_set: TagSet.meta } })

    Category.where(name: 'Q&A').last.update tag_set: TagSet.main
    Category.where(name: 'Meta').last.update tag_set: TagSet.meta

    # Set Meta tags as required/mod-only
    meta_category = Category.where(name: 'Meta').last
    meta_category.required_tags << Tag.unscoped.where(community: @community, name: required_tags)
    meta_category.moderator_tags << Tag.unscoped.where(community: @community, name: status_tags)

    Rails.cache.clear
    AuditLog.admin_audit(event_type: 'setup_site', related: @new_community, user: current_user,
                         comment: 'Site Settings updated via /admin/setup')

    render
  end

  def hellban
    @user = User.find params[:id]
    @user.block("user manually blocked by admin ##{current_user.id}")
    flash[:success] = t 'admin.user_fed_stat'
    redirect_back fallback_location: admin_path
  end

  def impersonate
    @user = User.find params[:id]
  end

  def change_users
    @user = User.find params[:id]

    unless params[:comment].present?
      flash[:danger] = 'Please explain why you are impersonating this user.'
      render :impersonate
      return
    end

    dev_id = current_user.id
    AuditLog.admin_audit(event_type: 'impersonation_start', related: @user, user: current_user,
                         comment: params[:comment])
    sign_in @user
    session[:impersonator_id] = dev_id
    flash[:success] = "You are now impersonating #{@user.username}."
    redirect_to root_path
  end

  def change_back
    return not_found unless session[:impersonator_id].present?

    @impersonator = User.find session[:impersonator_id]
  end

  def verify_elevation
    return not_found unless session[:impersonator_id].present?

    @impersonator = User.find session[:impersonator_id]
    if @impersonator&.valid_password? params[:password]
      session.delete :impersonator_id
      AuditLog.admin_audit(event_type: 'impersonation_end', related: current_user, user: @impersonator)
      sign_in @impersonator
      redirect_to root_path
    else
      flash[:danger] = 'Incorrect password.'
      render :change_back
    end
  end
end
