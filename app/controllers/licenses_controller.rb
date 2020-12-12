class LicensesController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin
  before_action :set_license, only: [:edit, :update, :toggle]

  def index
    @licenses = License.all.order(enabled: :desc, default: :desc, name: :asc)
  end

  def new
    @license = License.new
  end

  def create
    @license = License.new license_params
    if @license.save
      if @license.default?
        License.where(default: true).where.not(id: @license.id).update_all(default: false)
      end
      AuditLog.admin_audit(event_type: 'license_create', related: @license, user: current_user,
                           comment: "<<License #{@license.attributes_print}>>")
      redirect_to licenses_path
    else
      render :new, status: :bad_request
    end
  end

  def edit; end

  def update
    before = @license.attributes_print
    if @license.update license_params
      if @license.default?
        License.where(default: true).where.not(id: @license.id).update_all(default: false)
      end
      AuditLog.admin_audit(event_type: 'license_update', related: @license, user: current_user,
                           comment: "from <<License #{before}>>\nto <<License #{@license.attributes_print}>>")
      redirect_to licenses_path
    else
      render :edit, status: :bad_request
    end
  end

  def toggle
    before = @license.enabled?
    if @license.enabled? && (@license.default? || Category.where(license_id: @license.id).any?)
      flash[:danger] = "You can't disable a license that's currently in use."
    else
      @license.update(enabled: !@license.enabled)
      AuditLog.admin_audit(event_type: 'license_toggle', related: @license, user: current_user,
                           comment: "enabled from #{before}\nto #{@license.enabled?}")
    end
    redirect_to licenses_path
  end

  private

  def license_params
    params.require(:license).permit(:name, :url, :default)
  end

  def set_license
    @license = License.find params[:id]
  end
end
