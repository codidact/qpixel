class PostTypesController < ApplicationController
  before_action :authenticate_user!, except: [:list]
  before_action :verify_global_admin, except: [:list]
  before_action :set_post_type, only: [:edit, :update]

  def index
    @types = PostType.all
  end

  def list
    @types = PostType.all
    respond_to do |format|
      format.json do
        render json: @types
      end
    end
  end

  def new
    @type = PostType.new
  end

  def create
    @type = PostType.new post_type_params
    if @type.save
      clear_cache!
      redirect_to post_types_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if @type.update post_type_params
      clear_cache!
      redirect_to post_types_path
    else
      render :edit
    end
  end

  private

  def set_post_type
    @type = PostType.find(params[:id])
  end

  def post_type_params
    params.require(:post_type).permit(:name, :description, :has_answers, :has_votes, :has_tags, :has_parent,
                                      :has_category, :has_license, :is_public_editable, :is_closeable,
                                      :is_top_level, :is_freely_editable, :icon_name, :answer_type_id,
                                      :has_reactions, :has_only_specific_reactions)
  end

  def clear_cache!
    # FIXME: this is likely not clearing cache for rep changes
    Rails.cache.delete 'network/post_types/rep_changes'
    PostType.clear_cache
    current_community = RequestContext.community
    Community.all.each do |c|
      RequestContext.community = c
      Rails.cache.delete("post_type/#{@type.name}/reactions")
    end
    RequestContext.community = current_community
  end
end
