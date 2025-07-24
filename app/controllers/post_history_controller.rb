class PostHistoryController < ApplicationController
  def post
    @post = Post.find(params[:id])

    unless @post.can_access?(current_user)
      return not_found!
    end

    @history = PostHistory.where(post_id: params[:id])
                          .includes(:post_history_type, :user, post_history_tags: [:tag])
                          .order(created_at: :desc, id: :desc)
                          .paginate(per_page: 20, page: params[:page])

    if @post&.help_category.nil?
      render layout: 'without_sidebar'
    else
      render 'post_history/post', layout: 'without_sidebar', locals: { show_content: false }
    end
  end

  def slug_post
    @post = Post.by_slug(params[:slug], current_user)

    if @post.nil?
      return not_found!
    end

    @history = PostHistory.where(post_id: @post.id)
                          .includes(:post_history_type, :user)
                          .order(created_at: :desc, id: :desc)
                          .paginate(per_page: 20, page: params[:page])

    render 'post_history/post', layout: 'without_sidebar', locals: { show_content: false }
  end
end
