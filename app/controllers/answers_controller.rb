# Web controller. Provides actions that relate to answers. Pretty much the standard set of resources, really - it's
# questions that have a few more actions.
class AnswersController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :undelete]
  before_action :set_answer, only: [:edit, :update, :destroy, :undelete]
  @@markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(), extensions = {})

  # Authenticated web action. Creates a new answer as a resource for form creation in the view.
  def new
    @answer = Answer.new
    @question = Question.find params[:id]
  end

  # Supplies a pre-constructed Markdown renderer for use in rendering Markdown from views.
  def self.renderer
    @@markdown_renderer
  end

  # Authenticated web action. Based on the data submitted from the <tt>new</tt> view, creates a new answer. Assumes
  # that the route to this action contains the question id, and uses that to assign the answer to a question.
  def create
    @question = Question.find params[:id]
    @answer = Answer.new answer_params.merge(parent: @question, user: current_user, score: 0)
    @question.user.create_notification("New answer to your question '#{@question.title.truncate(50)}'", "/questions/#{@question.id}")
    if @answer.save
      redirect_to url_for(controller: :questions, action: :show, id: params[:id])
    else
      render :new, status: 422
    end
  end

  # Authenticated web action. Retrieves a single answer for editing.
  def edit
    check_your_privilege('Edit', @answer)
  end

  # Authenticated web action. Based on the information given in <tt>:edit</tt>, updates the answer.
  def update
    return unless check_your_privilege('Edit', @answer)
    PostHistory.post_edited(@answer, current_user)
    if @answer.update answer_params
      redirect_to url_for(controller: :questions, action: :show, id: @answer.parent.id)
    else
      render :edit
    end
  end

  # Authenticated web action. Deletes an answer - that is, applies the <tt>deleted</tt> attribute to it.
  def destroy
    return unless check_your_privilege('Delete', @answer)
    PostHistory.post_deleted(@answer, current_user)
    unless @answer.update(deleted: true, deleted_at: DateTime.now)
      flash[:error] = "The answer could not be deleted."
    end
    redirect_to url_for(controller: :questions, action: :show, id: @answer.parent.id)
  end

  # Authenticated web action. Removes the <tt>deleted</tt> attribute from an answer - that is, undeletes it.
  def undelete
    return unless check_your_privilege('Delete', @answer)
    PostHistory.post_undeleted(@answer, current_user)
    unless @answer.update(deleted: false, deleted_at: nil)
      flash[:error] = "The answer could not be undeleted."
    end
    redirect_to url_for(controller: :questions, action: :show, id: @answer.parent.id)
  end

  private
    # Sanitized parameters for use by question operations. All we need to let through here is the answer body - the user
    # shouldn't be able to supply any other information.
    def answer_params
      params.require(:answer).permit(:body)
    end

    def set_answer
      @answer = Answer.find params[:id]
    end
end

# Provides a custom HTML sanitization interface to use for cleaning up the HTML in answers.
class AnswerScrubber < Rails::Html::PermitScrubber
  # Sets up the scrubber instance with permissible tags and attributes.
  def initialize
    super
    self.tags = %w( a p b i em strong hr h1 h2 h3 h4 h5 h6 blockquote img strike del code pre br ul ol li )
    self.attributes = %w( href title src height width )
  end

  # Defines which nodes should be skipped when sanitizing HTML.
  def skip_node?(node)
    node.text?
  end
end
