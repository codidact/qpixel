class QuestionsController < ApplicationController
  def index
    @questions = Question.all.paginate(:page => params[:page], :per_page => 50)
  end

  def show
    @question = Question.find params[:id]
  end
end
