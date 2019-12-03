# Web controller. Provides actions that relate to users. Does not deal with accounts, registrations, sessions etc., as
# that's all handled by Devise and its override controllers (see <tt>app/controllers/users/*</tt>).
class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:edit_profile, :update_profile]
  before_action :verify_moderator, only: [:mod, :destroy, :soft_delete]
  before_action :set_user, only: [:mod, :destroy, :soft_delete]

  def index
    @users = User.all.includes(:posts).paginate(page: params[:page], per_page: 50).order(params[:sort])
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

    needs_transfer = ApplicationRecord.connection.tables.map { |t| [t, ApplicationRecord.connection.columns(t).map(&:name)] }
                                      .to_h.select { |_, cs| cs.include?('user_id') }
                                      .map { |k, _| k.singularize.classify.constantize rescue nil }.compact
    needs_transfer.each do |model|
      model.where(user_id: @user.id).update_all(user_id: SiteSetting['SoftDeleteTransferUser'])
    end

    unless @user.destroy
      render json: {status: 'failed', message: "Failed to destroy UID #{@user.id}"}, status: 500 and return
    end

    render json: {status: 'success', message: 'Ask a database administrator to verify the deletion is complete.'}
  end

  def edit_profile; end

  def update_profile
    profile_params = params.require(:user).permit(:username, :profile_markdown, :website, :twitter)
    profile_params[:twitter] = profile_params[:twitter].gsub('@', '')
    @user = current_user
    if @user.update(profile_params.merge(profile: QuestionsController.renderer.render(profile_params[:profile_markdown])))
      flash[:success] = "Your profile details were updated."
    else
      flash[:danger] = "Couldn't update your profile."
    end
    redirect_to edit_user_profile_path
  end

  private

  def set_user
    @user = User.find params[:id]
  end
end
