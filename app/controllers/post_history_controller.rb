class PostHistoryController < ApplicationController
  def post
    @post = Post.find(params[:id])

    unless @post.can_access?(current_user)
      return not_found
    end

    @history = PostHistory.where(post_id: params[:id]).visible(current_user)
                          .includes(:post_history_type, :user, post_history_tags: [:tag])
                          .order(created_at: :desc, id: :desc).paginate(per_page: 20, page: params[:page])
    render layout: 'without_sidebar'
  end
end
