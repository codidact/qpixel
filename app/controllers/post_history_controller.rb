class PostHistoryController < ApplicationController
  def post
    @post = Post.find(params[:id])

    unless @post.can_access?(current_user)
      return not_found
    end

    base_query = PostHistory.where(post_id: params[:id])
                            .includes(:post_history_type, :user, post_history_tags: [:tag])
                            .order(created_at: :desc, id: :desc)

    @history = base_query.paginate(per_page: 20, page: params[:page])

    @count = base_query.count

    @page = params[:page].nil? ? 1 : params[:page].to_i

    render layout: 'without_sidebar'
  end
end
