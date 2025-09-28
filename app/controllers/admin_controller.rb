# Web controller. Provides authenticated actions for use by administrators.
class AdminController < ApplicationController
  before_action :verify_admin, except: [:change_back, :verify_elevation]
  before_action :verify_global_admin, only: [:admin_email, :send_admin_email, :new_site, :create_site, :setup,
                                             :setup_save, :hellban, :all_email, :send_all_email]
  before_action :verify_developer, only: [:change_users, :impersonate]
  before_action :set_user, only: [:change_users, :hellban, :impersonate]

  skip_before_action :check_if_warning_or_suspension_pending, only: [:change_back, :verify_elevation]

  def index; end

  def error_reports
    base_scope = if current_user.global_admin?
                   ErrorLog.all
                 else
                   ErrorLog.where(community: RequestContext.community)
                 end

    if params[:type].present?
      base_scope = base_scope.where(klass: params[:type])
    end

    if params[:uuid].present?
      base_scope = base_scope.where(uuid: params[:uuid])
    end

    if params[:version].present? && params[:version] == 'current'
      sha, _date = helpers.current_commit
      base_scope = base_scope.where(version: sha)
    elsif params[:version].present?
      base_scope = base_scope.where(version: params[:version])
    end

    @reports = base_scope.newest_first.paginate(page: params[:page], per_page: 50)
    render layout: 'without_sidebar'
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
    return not_found! if type.nil?

    pre = @ability.send(:"#{type}_score_threshold")
    @ability.update("#{type}_score_threshold" => params[:threshold])
    AuditLog.admin_audit(event_type: 'ability_threshold_update', related: @ability, user: current_user,
                         comment: "#{params[:type]} score\nfrom <<#{pre}>>\nto <<#{params[:threshold]}>>")
    render json: { status: 'OK', privilege: @ability }, status: :accepted
  end

  def admin_email; end

  def send_admin_email
    community = RequestContext.community

    AdminMailer.with(body_markdown: params[:body_markdown],
                     subject: params[:subject],
                     community: community)
               .to_moderators
               .deliver_later

    AuditLog.admin_audit(event_type: 'send_admin_email', user: current_user,
                         comment: "Subject: #{params[:subject]}")

    flash[:success] = t('admin.email_being_sent')
    redirect_to admin_path
  end

  def all_email; end

  def send_all_email
    community = RequestContext.community

    Thread.new do
      emails = User.where.not(confirmed_at: nil).where('email NOT LIKE ?', '%localhost').select(:email).map(&:email)
      emails.each_slice(49) do |slice|
        AdminMailer.with(body_markdown: params[:body_markdown],
                         subject: params[:subject],
                         emails: slice, community: community)
                   .to_all_users
                   .deliver_later
      end
    end
    AuditLog.admin_audit(event_type: 'send_all_email', user: current_user,
                         comment: "Subject: #{params[:subject]}")
    flash[:success] = t 'admin.email_being_sent'
    redirect_to admin_path
  end

  def audit_log
    @page = helpers.safe_page(params)
    @per_page = helpers.safe_per_page(params)

    @log_types = AuditLog.unscoped.select(:log_type).distinct.map(&:log_type) - ['user_annotation', 'user_history']
    @event_types = AuditLog.unscoped.select(:event_type).distinct.map(&:event_type)

    @logs = if current_user.is_global_admin
              AuditLog.unscoped.where.not(log_type: ['user_annotation', 'user_history'])
            else
              AuditLog.where.not(log_type: ['block_log', 'user_annotation', 'user_history'])
            end

    [:log_type, :event_type].each do |key|
      if params[key].present?
        @logs = @logs.where(key => params[key])
      end
    end

    if params[:from].present?
      @logs = @logs.where('date(created_at) >= ?', params[:from])
    end

    if params[:to].present?
      @logs = @logs.where('date(created_at) <= ?', params[:to])
    end

    @logs = @logs.user_sort({ term: params[:sort], default: :created_at },
                            age: :created_at, type: :log_type, event: :event_type,
                            related: Arel.sql('related_type DESC, related_id DESC'), user: :user_id)
                 .paginate(page: @page, per_page: @per_page)

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
      analytics_url: 'AnalyticsURL', analytics_id: 'AnalyticsSiteId', content_transfer: 'AllowContentTransfer' }
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
    @user.block("user manually blocked by admin ##{current_user.id}")
    flash[:success] = t 'admin.user_fed_stat'
    redirect_back fallback_location: admin_path
  end

  def impersonate
    if Rails.env.development?
      change_users
    end
  end

  def change_users
    unless params[:comment].present? || Rails.env.development?
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
    return not_found! unless session[:impersonator_id].present?

    @impersonator = User.find session[:impersonator_id]
  end

  def verify_elevation
    return not_found! unless session[:impersonator_id].present?

    @impersonator = User.find session[:impersonator_id]
    if @impersonator&.sso_profile.present?
      session.delete :impersonator_id
      AuditLog.admin_audit(event_type: 'impersonation_end', related: current_user, user: @impersonator)
      sign_out @impersonator
      redirect_to new_saml_user_session_path
    elsif @impersonator&.valid_password? params[:password]
      session.delete :impersonator_id
      AuditLog.admin_audit(event_type: 'impersonation_end', related: current_user, user: @impersonator)
      sign_in @impersonator
      redirect_to root_path
    else
      flash[:danger] = 'Incorrect password.'
      render :change_back
    end
  end

  def do_email_query
    users = User.where(email: params[:email])
    if users.any?
      @user = users.first
      @profiles = @user.community_users.includes(:community).where(community: current_user.admin_communities)
    else
      flash[:danger] = helpers.i18ns('admin.errors.email_query_not_found')
    end
    render :email_query
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
