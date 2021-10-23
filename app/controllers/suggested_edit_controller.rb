class SuggestedEditController < ApplicationController
  before_action :set_suggested_edit, only: [:show, :approve, :reject]

  def category_index
    @category = params[:category].present? ? Category.find(params[:category]) : nil
    @edits = if params[:show_decided].present? && params[:show_decided] == '1'
               SuggestedEdit.where(post: Post.undeleted.where(category: @category), active: false) \
                            .order('created_at DESC')
             else
               SuggestedEdit.where(post: Post.undeleted.where(category: @category), active: true) \
                            .order('created_at ASC')
             end
  end

  def show
    render layout: 'without_sidebar'
  end

  def approve
    unless @edit.active?
      render json: { status: 'error', message: 'This edit has already been reviewed.' }, status: :conflict
      return
    end

    @post = @edit.post
    unless check_your_privilege('edit_posts', @post, false)
      render(json: { status: 'error', message: helpers.ability_err_msg(:edit_posts, 'review suggested edits') },
             status: :bad_request)

      return
    end

    opts = { before: @post.body_markdown, after: @edit.body_markdown, comment: @edit.comment,
             before_title: @post.title, after_title: @edit.title, before_tags: @post.tags, after_tags: @edit.tags }

    before = { before_body: @post.body, before_body_markdown: @post.body_markdown, before_tags_cache: @post.tags_cache,
               before_tags: @post.tags.to_a, before_title: @post.title }

    if @post.update(applied_details)
      @edit.update(before.merge(active: false, accepted: true, rejected_comment: '', decided_at: DateTime.now,
                                decided_by: current_user, updated_at: DateTime.now))
      PostHistory.post_edited(@post, @edit.user, **opts)
      flash[:success] = 'Edit approved successfully.'
      AbilityQueue.add(@edit.user, "Suggested Edit Approved ##{@edit.id}")
      render json: { status: 'success', redirect_url: post_path(@post) }
    else
      render json: { status: 'error', message: @post.errors.full_messages.join(', ') }, status: :bad_request
    end
  end

  def reject
    unless @edit.active?
      render json: { status: 'error', message: 'This edit has already been reviewed.' }, status: :conflict
      return
    end

    @post = @edit.post

    unless check_your_privilege('edit_posts', @post, false)
      render(json: { status: 'error', redirect_url: helpers.ability_err_msg(:edit_posts, 'review suggested edits') },
             status: :bad_request)

      return
    end

    now = DateTime.now

    if @edit.update(active: false, accepted: false, rejected_comment: params[:rejection_comment], decided_at: now,
                    decided_by: current_user, updated_at: now)
      flash[:success] = 'Edit rejected successfully.'
      AbilityQueue.add(@edit.user, "Suggested Edit Rejected ##{@edit.id}")
      render json: { status: 'success', redirect_url: helpers.generic_share_link(@post) }
    else
      render json: { status: 'error', redirect_url: 'Cannot reject this suggested edit... Strange.' },
             status: :bad_request
    end
  end

  private

  def set_suggested_edit
    @edit = SuggestedEdit.find(params[:id])
  end

  def applied_details
    {
      title: @edit.title,
      tags_cache: @edit.tags_cache&.reject(&:empty?),
      body: @edit.body,
      body_markdown: @edit.body_markdown,
      last_activity: DateTime.now,
      last_activity_by: @edit.user,
      last_edited_at: DateTime.now,
      last_edited_by: @edit.user
    }.compact
  end
end
