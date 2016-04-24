class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    @user.reputation = 1
    @user.save!
  end
end
