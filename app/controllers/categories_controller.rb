class CategoriesController < ApplicationController
  before_action :verify_admin, except: [:index, :show, :homepage]
  before_action :set_category, except: [:index, :homepage, :new, :create]

  def index
    @categories = Category.all.order(:name)
  end

  def show
    @posts = @category.posts.where(post_type_id: @category.display_post_types)
                      .order(last_activity: :asc)
                      .includes(:post_type).list_includes.paginate(page: params[:page], per_page: 50)
  end

  def homepage
    @category = Category.where(is_homepage: true).first
    @posts = @category.posts.where(post_type_id: @category.display_post_types)
                      .includes(:post_type).list_includes.paginate(page: params[:page], per_page: 50)
    render :show
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new category_params
    if @category.save
      if @category.is_homepage
        Category.where.not(id: @category.id).update_all(is_homepage: false)
      end
      flash[:success] = 'Your category was created.'
      redirect_to category_path(@category)
    else
      flash[:danger] = 'There were some errors while trying to save your category.'
      render :new
    end
  end

  def edit; end

  def update
    if @category.update category_params
      if @category.is_homepage
        Category.where.not(id: @category.id).update_all(is_homepage: false)
      end
      flash[:success] = 'Your category was updated.'
      redirect_to category_path(@category)
    else
      flash[:danger] = 'There were some errors while trying to save your category.'
      render :new
    end
  end

  def destroy
    unless @category.destroy
      flash[:danger] = "Couldn't delete that category."
    end
    redirect_back fallback_location: categories_path
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :short_wiki, :display_post_types, :post_type_ids, :tag_set_id, :is_homepage,
                                     :min_trust_level, :button_text)
  end
end
