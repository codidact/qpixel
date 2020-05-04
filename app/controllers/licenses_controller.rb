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
      redirect_to licenses_path
    else
      render :new, status: 400
    end
  end

  def edit; end

  def update
    if @license.update license_params
      if @license.default?
        License.where(default: true).where.not(id: @license.id).update_all(default: false)
      end
      redirect_to licenses_path
    else
      render :edit, status: 400
    end
  end

  def toggle
    if @license.enabled? && (@license.default? || Category.where(license_id: @license.id).any?)
      flash[:danger] = "You can't disable a license that's currently in use."
    else
      @license.update(enabled: !@license.enabled)
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
