class QuestionsController < ApplicationController
  before_action :authenticate_user!, :only => [:new, :create]

  def index
    @questions = Question.all.paginate(:page => params[:page], :per_page => 50)
  end

  def show
    @question = Question.find params[:id]
  end

  def tagged
    @questions = Question.where('tags like ?', "%#{params[:tag]}%")
  end

  def new
    @question = Question.new
  end

  def create
    params[:tags] = params[:tags].split(" ")
    @question = Question.new question_params
    @question.user = current_user
    if @question.save
      redirect_to url_for(:controller => :questions, :action => :show, :id => @question.id)
    else
      flash[:error] = "Your question could not be posted - please try again."
      redirect_to url_for(:controller => :questions, :action => :new)
    end
  end

  private
    def question_params
      params.require(:question).permit(:body, :title, :tags)
    end
end
