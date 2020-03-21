class TagsController < ApplicationController
  def index
    @tag_set = if params[:tag_set].present?
                 TagSet.find_by(name: params[:tag_set])
               else
                 nil
               end
    @tags = if params[:q].present?
              (@tag_set&.tags || Tag).where('name LIKE ?', "#{params[:q]}%")
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