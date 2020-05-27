# Web controller. Provides actions that relate to answers. Pretty much the standard set of resources, really - it's
# questions that have a few more actions.
class AnswersController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :undelete]
  before_action :set_answer, only: [:edit, :update, :destroy, :undelete]
  @@markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)

  def new
    @answer = Answer.new
    @question = Question.find params[:id]
  end

  def self.renderer
    @@markdown_renderer
  end

  def create
    @question = Question.find params[:id]
    @answer = Answer.new(answer_params.merge(parent: @question, user: current_user, score: 0,
                                             body: AnswersController.renderer.render(params[:answer][:body_markdown]),
                                             last_activity: DateTime.now, last_activity_by: current_user,
                                             category: @question.category))
    @question.user.create_notification("New answer to your question '#{@question.title.truncate(50)}'",
                                       share_question_url(@question))
    if @answer.save
      redirect_to url_for(controller: :questions, action: :show, id: params[:id])
    else
      render :new, status: 422
    end
  end

  def edit; end

  def update
    unless current_user&.has_post_privilege?('Edit', @answer)
      return update_as_suggested_edit
    end

    PostHistory.post_edited(@answer, current_user, before: @answer.body_markdown,
                                                    after: params[:answer][:body_markdown],
                                                    comment: params[:edit_comment])
    if @answer.update(answer_params.merge(body: AnswersController.renderer.render(params[:answer][:body_markdown]),
                                          last_activity: DateTime.now, last_activity_by: current_user))
      redirect_to url_for(controller: :questions, action: :show, id: @answer.parent.id)
    else
      render :edit
    end
  end

  def update_as_suggested_edit
    updates = {
      post: @answer,
      user: current_user,
      community: @answer.community,
      body: AnswersController.renderer.render(params[:answer][:body_markdown]),
      body_markdown: params[:answer][:body_markdown] != @answer.body_markdown ? params[:answer][:body_markdown] : nil,
      comment: params[:edit_comment],
      active: true, accepted: false,
      decided_at: nil, decided_by: nil,
      rejected_comment: nil
    }
    @edit = SuggestedEdit.new(updates)
    if @edit.save
      redirect_to url_for(controller: :questions, action: :show, id: @answer.parent.id)
    else
      @post.errors = @edit.errors
      render :edit
    end
  end

  def destroy
    unless check_your_privilege('Delete', @answer, false)
      flash[:danger] = 'You must have the Delete privilege to delete answers.'
      redirect_to(question_path(@answer.parent)) && return
    end

    if @answer.deleted
      flash[:danger] = "Can't delete a deleted answer."
      redirect_to(question_path(@answer.parent)) && return
    end

    if @answer.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user,
                      last_activity: DateTime.now, last_activity_by: current_user)
      PostHistory.post_deleted(@answer, current_user)
    else
      flash[:danger] = "Can't delete this answer right now. Try again later."
    end
    redirect_to question_path(@answer.parent)
  end

  def undelete
    unless check_your_privilege('Delete', @answer, false)
      flash[:danger] = 'You must have the Delete privilege to undelete answers.'
      redirect_to(question_path(@answer.parent)) && return
    end

    unless @answer.deleted
      flash[:danger] = "Can't undelete an undeleted answer."
      redirect_to(question_path(@answer.parent)) && return
    end

    if @answer.update(deleted: false, deleted_at: nil, deleted_by: nil,
                      last_activity: DateTime.now, last_activity_by: current_user)
      PostHistory.post_undeleted(@answer, current_user)
    else
      flash[:danger] = "Can't undelete this answer right now. Try again later."
    end
    redirect_to question_path(@answer.parent)
  end

  private

  def answer_params
    params.require(:answer).permit(:body_markdown)
  end

  def set_answer
    @answer = Answer.find params[:id]
  end
end
