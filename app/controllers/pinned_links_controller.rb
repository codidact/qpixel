class PinnedLinksController < ApplicationController
  before_action :verify_moderator
  before_action :set_pinned_link, only: [:edit, :update]
  before_action :verify_mod_on_current_community, only: [:edit, :update]

  def index
    @period = params[:period].presence || 'current'

    @links = if current_user.at_least_global_moderator? && params[:global] == '2'
               PinnedLink.unscoped
             elsif current_user.at_least_global_moderator? && params[:global] == '1'
               PinnedLink.where(community: nil)
             else
               PinnedLink.where(community: @community)
             end

    @links = case @period
             when 'past'
               @links.past
             when 'current'
               @links.current
             when 'future'
               @links.future
             else
               @links
             end

    @links = case params[:filter]
             when 'all'
               @links.all
             when 'inactive'
               @links.where(active: false).all
             else
               @links.where(active: true).all
             end

    render layout: 'without_sidebar'
  end

  def new
    @link = PinnedLink.new
  end

  def create
    @link = PinnedLink.new(pinned_link_params)

    if @link.save
      PinnedLink.audit_create(current_user, @link)
      flash[:success] = helpers.i18ns('pinned_links.success.create')
      redirect_to pinned_links_path
    else
      render 'pinned_links/new', status: :bad_request
    end
  end

  def edit; end

  def update
    before = @link.dup

    if @link.update(pinned_link_params)
      PinnedLink.audit_update(current_user, before, @link)
      flash[:success] = helpers.i18ns('pinned_links.success.update')
      redirect_to pinned_links_path
    else
      render 'pinned_links/edit', status: :bad_request
    end
  end

  private

  def set_pinned_link
    @link = if current_user.at_least_global_moderator?
              PinnedLink.unscoped.find params[:id]
            else
              PinnedLink.find params[:id]
            end
  end

  def pinned_link_params
    if current_user.at_least_global_moderator?
      params.require(:pinned_link).permit(:label, :link, :post_id, :active, :shown_before, :shown_after, :community_id)
    else
      params.require(:pinned_link).permit(:label, :link, :post_id, :active, :shown_before, :shown_after)
            .merge(community_id: RequestContext.community_id)
    end
  end

  def verify_mod_on_current_community
    if !current_user.at_least_global_moderator? && @link.community_id != RequestContext.community_id
      not_found!
    end
  end
end
