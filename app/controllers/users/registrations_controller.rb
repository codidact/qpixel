# An extended version of the Devise registrations controller, which is overridden so that we can add additional
# defaults before completing actions.
class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    @user.reputation = 1
    @user.save!
  end
end
