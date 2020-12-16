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
      format.json do
        render json: @tag_set
      end
    end
  end

  def update
    before = @tag_set.attributes_print
    if @tag_set.update(name: params[:name])
      render json: { tag_set: @tag_set, status: 'success' }
      AuditLog.admin_audit(event_type: 'tag_set_update', related: @tag_set, user: current_user,
                           comment: "from <<TagSet #{before}>>\nto <<TagSet #{@tag_set.attributes_print}>>")
    else
      render json: { tag_set: @tag_set, status: 'failed' }, status: :internal_server_error
    end
  end

  private

  def set_tag_set
    @tag_set = (current_user&.is_global_admin ? TagSet.unscoped : TagSet).find(params[:id])
  end
end
