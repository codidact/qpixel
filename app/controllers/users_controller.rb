# Web controller. Provides actions that relate to users. Does not deal with accounts, registrations, sessions etc., as
# that's all handled by Devise and its override controllers (see <tt>app/controllers/users/*</tt>).
class UsersController < ApplicationController
  # Web action. Retrieves a paginated list of all users.
  def index
    @users = User.all.paginate(:page => params[:page], :per_page => 50).order(params[:sort])
  end

  # Web action. Retrieves a single user.
  def show
    if user_signed_in? && get_setting('RestrictDBIntensiveOps') != 'true'
      @user = User.find params[:id]
    end
  end
end
