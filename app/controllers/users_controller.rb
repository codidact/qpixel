# Web controller. Provides actions that relate to users. Does not deal with accounts, registrations, sessions etc., as
# that's all handled by Devise and its override controllers (see <tt>app/controllers/users/*</tt>).
class UsersController < ApplicationController
  before_action :verify_moderator, only: [:mod, :destroy, :soft_delete]
  before_action :set_user, only: [:mod, :destroy, :soft_delete]

  def index
    @users = User.all.paginate(page: params[:page], per_page: 50).order(params[:sort])
  end

  def show
    @user = User.find params[:id]
  end

  def mod
  end

  def destroy
    if @user.votes.count > 100
      render json: {status: 'failed', message: 'Users with more than 100 votes cannot be destroyed.'}, status: 422 and return
    end

    if @user.is_admin || @user.is_moderator
      render json: {status: 'failed', message: 'Admins and moderators cannot be destroyed.'}, status: 422 and return
    end

    if @user.destroy!
      render json: {status: 'success'}
    else
      render json: {status: 'failed', message: 'Call to <code>@user.destroy!</code> failed; ask a DBA or dev to destroy.'}, status: 500
    end
  end

  def soft_delete
    if @user.is_admin || @user.is_moderator
      render json: {status: 'failed', message: 'Admins and moderators cannot be deleted.'}, status: 422 and return
    end

    @transfer_user = User.find params[:transfer]

    needs_transfer = ['questions', 'answers', 'votes']

    # User.reflections is a list of associations on the User model.
    User.reflections.keys.each do |assoc|
      # @user.public_send calls the method specified, so if assoc == 'questions', objects == @user.questions
      objects = @user.public_send(assoc)
      if needs_transfer.include?(assoc)
        objects.each do |obj|
          # Keep posts that score above 0 (but transfer them to @transfer_user), destroy the rest.
          if obj.respond_to?(:score) && obj.score < 0
            obj.destroy
          else
            obj.user_id = @transfer_user.id
            if !obj.save
              render json: {status: 'failed', message: "Failed to transfer #{assoc} #{obj.id}"}, status: 500 and return
            end
          end
        end
      else
        # If we don't need to transfer any of the objects of this type, just get rid of the lot.
        objects.destroy_all
      end
    end

    if !@user.destroy
      render json: {status: 'failed', message: "Failed to destroy UID #{@user.id}"}, status: 500 and return
    end

    render json: {status: 'success', message: 'Ask a database administrator to verify the deletion is complete.'}
  end

  private

  def set_user
    @user = User.find params[:id]
  end
end
