class SuggestedEditController < ApplicationController
    #require 'redcarpet/render_strip'
    before_action :set_suggested_edit, only: [:show, :approve, :reject]

    #@@plain_renderer = Redcarpet::Markdown.new(Redcarpet::Render::StripDown.new)

    #def self.renderer
    #    @@plain_renderer
    #end

    def show
        render layout: 'without_sidebar'
    end

    def approve
        return unless @edit.active?
        @post = @edit.post
        check_your_privilege('Edit', @post)

        body_rendered = QuestionsController.renderer.render(@edit.body_markdown)

        now = DateTime.now

        if @post.question?
            applied_details = {
                title: @edit.title,
                tags_cache: @edit.tags_cache&.reject(&:empty?),
                body: body_rendered,
                body_markdown: @edit.body_markdown,
                last_activity: now,
                last_activity_by: @edit.user
            }.compact
        elsif @post.answer?
            applied_details = {
                body: body_rendered,
                body_markdown: @edit.body_markdown,
                last_activity: now,
                last_activity_by: @edit.user
            }.compact
        end

        PostHistory.post_edited(@post, @edit.user, before: @post.body_markdown,
            after: @edit.body_markdown, comment: params[:edit_comment])

        if @post.update(applied_details)
            @edit.update(active: false, accepted: true, rejected_comment: '', decided_at: now, decided_by: current_user, updated_at: now)
            if @post.question?
                render(json: { status: 'success', redirect_url: url_for(controller: :posts, action: :share_q, id: @post.id) }, status: 200)
            elsif @post.answer?
                render(json: { status: 'success', redirect_url: url_for(controller: :posts, action: :share_a, qid: @post.parent.id, id: @post.id) }, status: 200)
            end
            return
        else
            render(json: { status: 'error', redirect_url: 'There are issues with this suggested edit. It does not fulfill the post criteria. Reject and make the changes yourself.' }, status: 400)
        end

        render(json: { status: 'error', redirect_url: 'Could not approve suggested edit.' }, status: 400)
        return
    end

    def reject
        return unless @edit.active?
        @post = @edit.post
        check_your_privilege('Edit', @post)

        now = DateTime.now

        if @edit.update(active: false, accepted: false, rejected_comment: params[:rejection_comment], decided_at: now, decided_by: current_user, updated_at: now)
            render(json: { status: 'success' }, status: 200)
            return
        else
            render(json: { status: 'error', redirect_url: 'Cannot reject this suggested edit... Strange.' }, status: 400)
        end
    end

    def set_suggested_edit
        @edit = SuggestedEdit.find(params[:id])
    end
end