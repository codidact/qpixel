class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:document]
  before_action :set_post, except: [:new, :create, :document]
  before_action :check_permissions, except: [:new, :create, :document]
  before_action :verify_moderator, only: [:new, :create]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(new_post_params.merge(body: QuestionsController.renderer.render(params[:post][:body_markdown]),
                                           user: User.find(-1)))

    if @post.policy_doc? && !current_user.is_admin
      @post.errors.add(:base, 'You must be an administrator to create a policy document. Moderators may only create help documents.')
      render :new and return
    end

    if @post.save
      redirect_to policy_path(slug: @post.doc_slug)
    else
      render :new
    end
  end

  def edit; end

  def update
    PostHistory.post_edited(@post, current_user, before: @post.body_markdown, after: params[:post][:body_markdown])
    if @post.update(post_params.merge(body: QuestionsController.renderer.render(params[:post][:body_markdown]),
                                      last_activity: DateTime.now, last_activity_by: current_user))
      redirect_to policy_path(slug: @post.doc_slug)
    else
      render :edit
    end
  end

  def document
    @post = Post.find_by(doc_slug: params[:slug])
  end

  private

  def new_post_params
    params.require(:post).permit(:post_type_id, :title, :doc_slug, :body_markdown)
  end

  def post_params
    params.require(:post).permit(:title, :body_markdown)
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def check_permissions
    if @post.post_type_id == HelpDoc.post_type_id
      verify_moderator
    elsif @post.post_type_id == PolicyDoc.post_type_id
      verify_admin
    else
      not_found
    end
  end
end