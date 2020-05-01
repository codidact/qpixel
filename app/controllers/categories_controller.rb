class CategoriesController < ApplicationController
  before_action :verify_admin, except: [:index, :show, :homepage]
  before_action :set_category, except: [:index, :homepage, :new, :create]

  def index
    @categories = Category.all.order(:name)
  end

  def show
    set_last_visit(@category)
    set_list_posts
  end

  def homepage
    @category = Category.where(is_homepage: true).first
    set_list_posts
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
      Rails.cache.delete "#{RequestContext.community_id}/header_categories"
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
      Rails.cache.delete "#{RequestContext.community_id}/header_categories"
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
    params.require(:category).permit(:name, :short_wiki, :tag_set_id, :is_homepage, :min_trust_level, :button_text,
                                     :color_code, display_post_types: [], post_type_ids: [])
  end

  def set_list_posts
    sort_params = { activity: { last_activity: :desc }, age: { created_at: :desc }, score: { score: :desc },
                    lottery: [Arel.sql('(RAND() - ? * DATEDIFF(CURRENT_TIMESTAMP, posts.created_at)) DESC'),
                              SiteSetting['LotteryAgeDeprecationSpeed']] }
    sort_param = sort_params[params[:sort]&.to_sym] || { last_activity: :desc }
    @posts = @category.posts.undeleted.where(post_type_id: @category.display_post_types)
                      .includes(:post_type).list_includes.paginate(page: params[:page], per_page: 50)
                      .order(sort_param)
  end

  def set_last_visit(category)
    return unless current_user.present?
    key = "#{RequestContext.community_id}/#{current_user.id}/#{category.id}/last_visit"
    RequestContext.redis.set key, DateTime.now.to_s
    Rails.cache.delete key
  end
end
