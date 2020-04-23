class TagsController < ApplicationController
  def index
    @tag_set = if params[:tag_set].present?
                 TagSet.find(params[:tag_set])
               end
    @tags = if params[:term].present?
              (@tag_set&.tags || Tag).where('name LIKE ?', "#{params[:term]}%")
            else
              @tag_set&.tags || Tag.all
            end.order(:name).paginate(page: params[:page], per_page: 50)
    respond_to do |format|
      format.json do
        render json: @tags
      end
    end
  end
end
