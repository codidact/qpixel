class SuggestedEditController < ApplicationController
  before_action :set_suggested_edit, only: [:show, :approve, :reject]

  def show
    render layout: 'without_sidebar'
  end

  def approve
    unless @edit.active?
      render json: { status: 'error', message: 'This edit has already been reviewed.' }, status: 409
      return
    end

    @post = @edit.post
    unless check_your_privilege('Edit', @post, false)
      render(json: { status: 'error', message: 'You need the Edit privilege to approve edits' }, status: 400)

      return
    end

    opts = { before: @post.body_markdown, after: @edit.body_markdown, comment: params[:edit_comment] }
    if @post.question? || @post.article?
      opts.merge(before_title: @post.title, after_title: @edit.title, before_tags: @post.tags, after_tags: @edit.tags)
    end

    before = { before_body: @post.body, before_body_markdown: @post.body_markdown, before_tags_cache: @post.tags_cache,
               before_tags: @post.tags.to_a, before_title: @post.title }

    if @post.update(applied_details)
      @edit.update(before.merge(active: false, accepted: true, rejected_comment: '', decided_at: DateTime.now,
                                decided_by: current_user, updated_at: DateTime.now))
      PostHistory.post_edited(@post, @edit.user, **opts)
      flash[:success] = 'Edit approved successfully.'
      if @post.question?
        render(json: { status: 'success', redirect_url: url_for(controller: :posts, action: :share_q, id: @post.id) })

      elsif @post.answer?
        render(json: { status: 'success', redirect_url: url_for(controller: :posts, action: :share_a,
                                                        qid: @post.parent.id, id: @post.id) })
      elsif @post.article?
        render(json: { status: 'success', redirect_url: url_for(controller: :articles, action: :share, id: @post.id) })
      else
        render(json: { status: 'error', message: 'Could not approve suggested edit.' }, status: 400)
      end
    else
      render json: { status: 'error',
                     message: @post.errors.full_messages.join(', ') }, status: 400
    end
  end

  def reject
    unless @edit.active?
      render json: { status: 'error', message: 'This edit has already been reviewed.' }, status: 409
      return
    end

    @post = @edit.post

    unless check_your_privilege('Edit', @post, false)
      render(json: { status: 'error', redirect_url: 'You need the Edit privilege to reject edits' }, status: 400)

      return
    end

    now = DateTime.now

    if @edit.update(active: false, accepted: false, rejected_comment: params[:rejection_comment], decided_at: now,
                                                    decided_by: current_user, updated_at: now)
      flash[:success] = 'Edit rejected successfully.'
      if @post.question?
        render(json: { status: 'success', redirect_url: url_for(controller: :posts, action: :share_q,
                                                                id: @post.id) })
      elsif @post.answer?
        render(json: { status: 'success', redirect_url: url_for(controller: :posts, action: :share_a,
                                                        qid: @post.parent.id, id: @post.id) })
      elsif @post.article?
        render(json: { status: 'success', redirect_url: url_for(controller: :articles, action: :share,
          id: @post.id) })
      end
    else
      render(json: { status: 'error', redirect_url: 'Cannot reject this suggested edit... Strange.' }, status: 400)
    end
  end

  private

  def set_suggested_edit
    @edit = SuggestedEdit.find(params[:id])
  end

  def applied_details
    if @post.question? || @post.article?
      {
        title: @edit.title,
        tags_cache: @edit.tags_cache&.reject(&:empty?),
        body: @edit.body,
        body_markdown: @edit.body_markdown,
        last_activity: DateTime.now,
        last_activity_by: @edit.user,
        last_edited_at: DateTime.now,
        last_edited_by_id: @edit.user
      }.compact
    elsif @post.answer?
      {
        body: @edit.body,
        body_markdown: @edit.body_markdown,
        last_activity: DateTime.now,
        last_activity_by: @edit.user,
        last_edited_at: DateTime.now,
        last_edited_by_id: @edit.user
      }.compact
    end
  end
end
