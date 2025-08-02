class PinnedLinksController < ApplicationController
  before_action :verify_moderator
  before_action :set_pinned_link, only: [:edit, :update]
  before_action :verify_mod_on_current_community, only: [:edit, :update]

  def index
    links = if current_user.at_least_global_moderator? && params[:global] == '2'
              PinnedLink.unscoped
            elsif current_user.at_least_global_moderator? && params[:global] == '1'
              PinnedLink.where(community: nil)
            else
              PinnedLink.where(community: @community)
            end
    @links = case params[:filter]
             when 'all'
               links.all
             when 'inactive'
               links.where(active: false).all
             else
               links.where(active: true).all
             end
    render layout: 'without_sidebar'
  end

  def new
    @link = PinnedLink.new
  end

  def create
    @link = PinnedLink.new(pinned_link_params)

    if @link.save
      attr = @link.attributes_print

      AuditLog.moderator_audit(event_type: 'pinned_link_create',
                               related: @link,
                               user: current_user,
                               comment: "<<PinnedLink #{attr}>>")

      flash[:success] =
        'Your pinned link has been created. Due to caching, it may take some time until it is shown.'
      redirect_to pinned_links_path
    else
      render 'pinned_links/new', status: :bad_request
    end
  end

  def edit; end

  def update
    before = @link.attributes_print

    if @link.update(pinned_link_params)
      after = @link.attributes_print

      AuditLog.moderator_audit(event_type: 'pinned_link_update',
                               related: @link,
                               user: current_user,
                               comment: "from <<PinnedLink #{before}>>\nto <<PinnedLink #{after}>>")

      flash[:success] = 'The pinned link has been updated. Due to caching, it may take some time until it is shown.'
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
