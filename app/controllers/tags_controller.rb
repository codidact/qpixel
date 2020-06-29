class TagsController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update]
  before_action :set_category, except: [:index]
  before_action :set_tag, only: [:show, :edit, :update]

  def index
    @tag_set = if params[:tag_set].present?
                 TagSet.find(params[:tag_set])
               end
    @tags = if params[:term].present?
              (@tag_set&.tags || Tag).search(params[:term])
            else
              (@tag_set&.tags|| Tag.all).order(:name)
            end.paginate(page: params[:page], per_page: 50)
    respond_to do |format|
      format.json do
        render json: @tags
      end
    end
  end

  def category
    @tag_set = @category.tag_set
    @tags = if params[:q].present?
              @tag_set.tags.search(params[:q])
            else
              @tag_set.tags.left_joins(:posts).group(Arel.sql('tags.id')).order(Arel.sql('COUNT(posts.id) DESC'))
                      .select(Arel.sql('tags.*, COUNT(posts.id) AS post_count'))
            end
  end

  def show; end

  def edit

  end

  def update

  end

  private

  def set_tag
    @tag = Tag.find params[:tag_id]
    required_ids = @category&.required_tag_ids
    moderator_ids = @category&.moderator_tag_ids
    topic_ids = @category&.topic_tag_ids
    required = required_ids&.include?(@tag.id) ? 'is-filled' : ''
    topic = topic_ids&.include?(@tag.id) ? 'is-outlined' : ''
    moderator = moderator_ids&.include?(@tag.id) ? 'is-red is-outlined' : ''
    @classes = "badge is-tag #{required} #{topic} #{moderator}"
  end

  def set_category
    @category = Category.find params[:id]
  end
end
