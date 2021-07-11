class ReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator, except: [:add, :retract]
  before_action :set_post, only: [:add, :retract]
  before_action :set_reaction_type, only: [:edit, :update]

  def add
    reaction_type = ReactionType.find(params[:reaction_id])
    comment_text = params[:comment]
    comment = nil

    if !comment_text.blank?
      if @post.comments_disabled && !current_user.is_moderator && !current_user.is_admin
        render json: { status: 'failed', message: 'Comments have been disabled on this post.' }, status: :forbidden
        return
      end

      thread = CommentThread.where(title: reaction_type.name, post: @post).last
      thread ||= CommentThread.new(title: reaction_type.name, post: @post)

      comment = Comment.new(post: @post, content: comment_text, user: current_user, comment_thread: thread)
    elsif reaction_type.requires_comment
      render json: { status: 'failed', message: 'This reaction type requires a comment with an explanation.' },
             status: :forbidden
      return
    end

    old_reaction = Reaction.where(user: current_user, post: @post, reaction_type: reaction_type)
    if old_reaction.any?
      render json: { status: 'failed', message: 'You already added this reaction to this post.' },
             status: :forbidden
      return
    end

    reaction = Reaction.new(user: current_user, post: @post, reaction_type: reaction_type, comment: comment)

    ActiveRecord::Base.transaction do
      thread&.save!
      comment&.save!
      reaction.save!
    end

    render json: { status: 'success' }
  end

  def retract
    reaction_type = ReactionType.find(params[:reaction_id])

    reaction = Reaction.where(user: current_user, post: @post, reaction_type: reaction_type)
    unless reaction.any?
      render json: { status: 'failed', message: 'You do not have any reactions of this type on this post.' },
             status: :forbidden
      return
    end

    reaction.first.destroy
    render json: { status: 'success' }
  end

  def index; end

  def edit; end

  def update
    @reaction_type.update name: params[:reaction_type][:name],
                          description: params[:reaction_type][:description], 
                          on_post_label: params[:reaction_type][:on_post_label],
                          color: params[:reaction_type][:color],
                          icon: params[:reaction_type][:icon],
                          requires_comment: params[:reaction_type][:requires_comment]
    render :edit
  end

  def new; end

  def create; end

  def delete; end

  protected

  def set_post
    @post = Post.find(params[:post_id])
    unless @post.can_access?(current_user)
      not_found
    end
  end

  def set_reaction_type
    @reaction_type = ReactionType.find(params[:id])
  end
end
