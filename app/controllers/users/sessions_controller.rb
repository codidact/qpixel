# An extended version of the Devise sessions controller. Don't know why I overrode this one, I haven't had cause to
# change login yet.
class Users::SessionsController < Devise::SessionsController
  # def new
  #   super
  # end

  # def create
  #   super
  # end
end
