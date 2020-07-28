class PinnedLinksController < ApplicationController
    before_action :verify_moderator
    before_action :set_pinned_link, only: [:edit, :update]

    def index
        if current_user.is_global_moderator && params[:global] == '2'
            links = PinnedLink.unscoped
        elsif current_user.is_global_moderator && params[:global] == '1'
            links = PinnedLink.where(community: nil)
        else
            links = PinnedLink.where(community: @community)
        end
        if params[:filter] == 'all'
            @links = links.all
        elsif params[:filter] == 'inactive'
            @links = links.where(active: false).all
        else
            @links = links.where(active: true).all
        end
        render layout: 'without_sidebar'
    end

    def new
        @link = PinnedLink.new
    end

    def create
        data = pinned_link_params
        post = !data[:post_id].present? ? nil : Post.where(data[:post_id]).first
        community = !data[:community].present? ? nil : Community.where(data[:community]).first
        
        @link = PinnedLink.create data.merge(post: post, community: community)

        attr = @link.attributes.map { |k, v| "#{k}: #{v}" }.join(' ')
        AuditLog.moderator_audit(event_type: 'pinned_link_create', related: @link, user: current_user,
                                comment: "<<PinnedLink #{attr}>>")

        flash[:success] = 'Your pinned link has been created. Due to caching, it may take some time, '\
                          'until it is shown.'
        redirect_to pinned_links_path
    end

    def edit
        unless current_user.is_global_moderator
            return not_found if @link.community.id != @community.id
        end
    end

    def update
        unless current_user.is_global_moderator
            return not_found if @link.community.id != @community.id
        end

        before = @link.attributes.map { |k, v| "#{k}: #{v}" }.join(' ')
        data = pinned_link_params
        post = !data[:post_id].present? ? nil : Post.where(data[:post_id]).first
        community = !data[:community].present? ? nil : Community.where(data[:community]).first
        @link.update data.merge(post: post, community: community)
        after = @link.attributes.map { |k, v| "#{k}: #{v}" }.join(' ')
        AuditLog.moderator_audit(event_type: 'pinned_link_update', related: @link, user: current_user,
                                comment: "from <<PinnedLink #{before}>>\nto <<PinnedLink #{after}>>")

        flash[:success] = 'The pinned link has been updated. Due to caching, it may take some time, ' \
                          'until it is shown.'
        redirect_to pinned_links_path
    end

    private
    def set_pinned_link
        @link = PinnedLink.find params[:id]
    end

    def pinned_link_params
        if current_user.is_global_moderator
            params.require(:pinned_link).permit(:label, :link, :post, :active, :shown_before, :shown_after, :community)
        else
            params.require(:pinned_link).permit(:label, :link, :post, :active, :shown_before, :shown_after)
        end
    end
end
