class MicroAuth::AppsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_app, except: [:index, :new, :create]
  before_action :verify_ownership, except: [:index, :new, :create]

  def index
    @all_apps = if params[:admin].present? && helpers.admin?
                  MicroAuth::App.all
                else
                  MicroAuth::App.where(user: current_user)
                end
    @apps = if params[:search].present?
              @all_apps.where('name LIKE ?', "#{params[:search]}%")
            else
              @all_apps
            end.order(name: :asc).paginate(page: params[:page], per_page: 30)
  end

  def new
    @app = MicroAuth::App.new
  end

  def create
    @app = MicroAuth::App.new(app_params.merge({
                                                 public_key: SecureRandom.base58(32),
      secret_key: SecureRandom.base58(32),
      app_id: generate_app_id,
      user: current_user
                                               }))
    if @app.save
      redirect_to oauth_app_path(@app.app_id)
    else
      flash[:danger] = 'There was an error while trying to create your app.'
      render :new
    end
  end

  def show
    @data = [
      { name: 'Authentications', data: @app.tokens.group_by_week(:created_at).count },
      { name: 'Users', data: @app.tokens.group_by_week(:created_at).count('DISTINCT user_id') }
    ]
  end

  def edit; end

  def update
    if @app.update app_params
      redirect_to oauth_app_path(@app.app_id)
    else
      flash[:danger] = 'There was an error while trying to update your app.'
    end
  end

  def deactivate
    @app.update(active: false, deactivated_by: current_user, deactivated_at: DateTime.now,
                deactivate_comment: params[:comment])
    flash[:success] = 'App deactivated.'
    redirect_to oauth_app_path(@app.app_id)
  end

  private

  def set_app
    @app = MicroAuth::App.find_by app_id: params[:id]
  end

  def verify_ownership
    not_found unless @app.user == current_user || helpers.admin?
  end

  def app_params
    params.require(:micro_auth_app).permit(:name, :description, :auth_domain)
  end

  def generate_app_id
    loop do
      candidate = SecureRandom.base58(10)
      if MicroAuth::App.find_by(app_id: candidate).nil?
        return candidate
      end
    end
  end
end
