# Web controller. Provides actions that relate to users. Does not deal with accounts, registrations, sessions etc., as
# that's all handled by Devise and its override controllers (see <tt>app/controllers/users/*</tt>).
class UsersController < ApplicationController
  before_action :verify_moderator, :only => [:mod, :destroy, :soft_delete]
  before_action :set_user, :only => [:mod, :destroy, :soft_delete]

  # Web action. Retrieves a paginated list of all users.
  def index
    @users = User.all.paginate(:page => params[:page], :per_page => 50).order(params[:sort])
  end

  # Web action. Retrieves a single user.
  def show
    if user_signed_in? || get_setting('RestrictDBIntensiveOps') != 'true'
      @user = User.find params[:id]
    end
  end

  def mod
  end

  def destroy
    if @user.votes.count > 100
      render :json => { :status => 'failed', :message => 'Users with more than 100 votes cannot be destroyed.' }, :status => 422 and return
    end

    if @user.is_admin || @user.is_moderator
      render :json => { :status => 'failed', :message => 'Admins and moderators cannot be destroyed.' }, :status => 422 and return
    end

    @user.destroy!
    render :json => { :status => 'success' }
  end

  def soft_delete
    @transfer_user = User.find params[:transfer]

    needs_transfer = ['questions', 'answers', 'comments', 'votes']

    # User.reflections is a list of associations on the User model.
    User.reflections.keys.each do |assoc|
      # @user.public_send calls the method specified, so if assoc == 'questions', objects == @user.questions
      objects = @user.public_send(assoc)
      if needs_transfer.include?(assoc)
        objects.each do |obj|
          # Keep posts that score above 0 (but transfer them to @transfer_user), destroy the rest.
          unless obj.respond_to?(:score) && obj.score >= 0
            obj.destroy
          else
            obj.user_id = @transfer_user.id
          end
        end
      else
        # If we don't need to transfer any of the objects of this type, just get rid of the lot.
        objects.destroy_all
      end
    end
  end

  private
    def set_user
      @user = User.find params[:id]
    end
end
