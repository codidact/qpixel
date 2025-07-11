class SudoController < ApplicationController
  before_action :authenticate_user!

  def sudo; end

  def enter_sudo
    if current_user.valid_password? params[:password]
      session[:sudo] = DateTime.now.iso8601
      redirect_to session[:sudo_return]
    else
      flash[:danger] = 'The password you entered was incorrect.'
      render :sudo
    end
  end
end
