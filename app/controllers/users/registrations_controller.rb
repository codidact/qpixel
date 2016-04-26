# An extended version of the Devise registrations controller, which is overridden so that we can add additional
# defaults before completing actions.
class Users::RegistrationsController < Devise::RegistrationsController
  # Extends the Devise default RegistrationsController#create. Additionally initializes a reputation score
  # (defaults to 0) for the newly-created user.
  def create
    super
    @user.reputation = 1
    @user.save!
  end
end
