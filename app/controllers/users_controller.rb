require 'net/http'

class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:edit_profile, :update_profile, :stack_redirect, :transfer_se_content]
  before_action :verify_moderator, only: [:mod, :destroy, :soft_delete]
  before_action :set_user, only: [:mod, :destroy, :soft_delete, :posts]

  def index
    sort_param = {reputation: :reputation, age: :created_at}[params[:sort]&.to_sym] || :reputation
    @users = if params[:search].present?
               user_scope.where('username LIKE ?', "#{params[:search]}%")
             else
               user_scope.order(sort_param => :desc)
             end.list_includes.paginate(page: params[:page], per_page: 48)
  end

  def show
    @user = user_scope.find params[:id]
  end

  def posts
    post_types = {questions: Question, answers: Answer}
    unless post_types.include? params[:type].to_sym
      respond_to do |format|
        format.html do
          render plain: 'No type or invalid type specified (must be one of questions, answers)', status: 400
        end
        format.json do
          render json: { status: 'invalid', message: 'No type or invalid type specified (must be one of questions, answers)' },
                 status: 400
        end
      end
      return
    end

    model = post_types[params[:type].to_sym]
    @posts = model.undeleted.where(user: @user).user_sort({term: params[:sort], default: :score},
                                                          {age: :created_at, score: :score})
                  .paginate(page: params[:page], per_page: 25)
    respond_to do |format|
      format.html do
        render :posts
      end
      format.json do
        render json: @posts
      end
    end
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

    if profile_params[:website].present? && URI.parse(profile_params[:website]).is_a?(URI::Generic)
      # URI::Generic indicates the user didn't include a protocol, so we'll add one now so that it can be
      # parsed correctly in the view later on.
      profile_params[:website] = 'https://' + profile_params[:website]
    end

    @user = current_user

    if params[:user][:avatar].present?
      @user.avatar.attach(params[:user][:avatar])
    end

    if @user.update(profile_params.merge(profile: QuestionsController.renderer.render(profile_params[:profile_markdown])))
      flash[:success] = "Your profile details were updated."
    else
      flash[:danger] = "Couldn't update your profile."
    end
    redirect_to edit_user_profile_path
  end

  def stack_redirect
    response = Net::HTTP.post_form(URI('https://stackoverflow.com/oauth/access_token/json'),
                                   { 'client_id' => SiteSetting['SEApiClientId'], 'client_secret' => SiteSetting['SEApiClientSecret'],
                                     'code' => params[:code], 'redirect_uri' => stack_redirect_url })
    access_token = JSON.parse(response.body)['access_token']

    uri = "https://api.stackexchange.com/2.2/me/associated?key=#{SiteSetting['SEApiKey']}&access_token=#{access_token}&filter=!-rH86dva"
    accounts = JSON.parse(Net::HTTP.get(URI(uri)))
    network_id = accounts['items'][0]['account_id']
    current_user.update(se_acct_id: network_id)
    redirect_to edit_user_profile_path
  end

  def transfer_se_content
    unless params[:agree_to_relicense].present? && params[:agree_to_relicense] == 'true'
      flash[:danger] = "To claim your content, we need you to agree to relicense your posts to us."
      redirect_to edit_user_profile_path and return
    end

    auto_user = user_scope.where(se_acct_id: current_user.se_acct_id).where.not(id: current_user.id).first
    if auto_user.nil?
      flash[:warning] = "There doesn't appear to be any of your content here."
      redirect_to edit_user_profile_path and return
    end

    Thread.new do
      auto_user.posts.each do |post|
        post.reassign_user(current_user)
        post.remove_attribution_notice!
      end
      auto_user.reload.destroy
      current_user.update(transferred_content: true)
    end
    flash[:success] = "Your content is being transferred to you."
    redirect_to edit_user_profile_path
  end

  private

  def set_user
    @user = user_scope.find params[:id]
  end

  def user_scope
    User.joins(:community_user)
  end
end
