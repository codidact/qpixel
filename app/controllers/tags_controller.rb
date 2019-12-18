class TagsController < ApplicationController
  def index
    @tags = if params[:q].present?
              Tag.where('name LIKE ?', "#{params[:q]}%")
            else
              Tag.all
            end.paginate(page: params[:page], per_page: 50)
    respond_to do |format|
      format.json do
        render json: @tags
      end
    end
  end
end