class CategoriesController < ApplicationController
  before_action :verify_admin, except: [:index, :show]
  before_action :set_category, except: [:index]

  def index
    @categories = Category.all.order(:name)
  end

  def show
    @posts = @category.posts.joins(:post_type).where(post_types: { name: @category.display_post_types })
                      .includes(:post_type).paginate(page: params[:page], per_page: 50)
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end
end
