class PostHistoryController < ApplicationController
  def post
    @post = Post.find(params[:id])
    
    if @post.deleted? && !current_user&.has_post_privilege?('flag_curate', @post)
      return not_found
    end
    
    @history = PostHistory.where(post_id: params[:id]).includes(:post_history_type, :user, post_history_tags: [:tag])
                          .order(created_at: :desc).paginate(per_page: 20, page: params[:page])
    render layout: 'without_sidebar'
  end
end
