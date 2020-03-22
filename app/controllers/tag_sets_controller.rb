class TagSetsController < ApplicationController
  before_action :verify_admin
  before_action :verify_global_admin, only: [:global]
  before_action :set_tag_set, except: [:index, :global]

  def index
    @tag_sets = TagSet.all.includes(:community)
    @counts = @tag_sets.left_joins(:tags).group(:id).count(Arel.sql('tags.id'))
  end

  def global
    @tag_sets = TagSet.unscoped.all.includes(:community)
    @counts = @tag_sets.left_joins(:tags).group(:id).count(Arel.sql('tags.id'))
    render :index
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: @tag_set
      end
    end
  end

  def update
    if @tag_set.update(name: params[:name])
      render json: { tag_set: @tag_set, status: 'success' }
    else
      render json: { tag_set: @tag_set, status: 'failed' }, status: 500
    end
  end

  private

  def set_tag_set
    @tag_set = (current_user&.is_global_admin ? TagSet.unscoped : TagSet).find(params[:id])
  end
end
