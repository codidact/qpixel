# Manages OAuth (sort of) authentication requests and token requests.
#
# Authentication flow:
#  * App sends user to GET :initiate with query string params:
#    * app_id
#    * scope (optional)
#    * state (optional)
#    * redirect_uri (optional)
#  * User approves app (or if they reject it, no further action). Generate MicroAuth::Token.
#  * If redirect_uri was provided:
#    * If it's under the app's authentication_domain, redirect the user to it. No further action
#      until a token request is received. Send params:
#      * code (MicroAuth::Token.code)
#      * state (exactly as sent to us in the request to :initiate)
#    * If it's not, show an error screen to the user.
#  * If redirect_uri NOT provided, show an 'App Approved' screen to the user containing the
#    MicroAuth::Token.code.
#
# Next step is for the app to send a token request.
#
#  * POST :token with params:
#    * app_id
#    * code
#    * secret (iff redirect_uri was provided to :initiate)
#  * Response is either an error (if details do not match), or a successful response containing
#    `token` and `expires_at` parameters in a JSON object. `expires_at` is set only if `scope` does
#    not include `perpetual`.
#
class MicroAuth::AuthenticationController < ApplicationController
  before_action :authenticate_user!, only: [:initiate, :approve, :reject]
  before_action :set_app, only: [:initiate, :approve]
  skip_before_action :verify_authenticity_token, only: [:token]

  def initiate; end

  def approve
    @token = MicroAuth::Token.create(user: current_user, app: @app, token: SecureRandom.base58(32),
                                     code: SecureRandom.base58(6), code_expires_at: 10.minutes.from_now,
                                     scope: clean_scope(params[:scope]), redirect_uri: params[:redirect_uri],
                                     expires_at: params[:scope].include?('perpetual') ? nil : 28.days.from_now)
    if params[:redirect_uri].present? && @app.valid_redirect?(params[:redirect_uri])
      redirect_to helpers.construct_redirect(params[:redirect_uri], code: @token.code, state: params[:state])
    elsif params[:redirect_uri].present?
      render :approval_redirect_error, status: 400
    else
      render :approved
    end
  end

  def reject; end

  def token
    @app = MicroAuth::App.find_by app_id: params[:app_id], secret_key: params[:secret]
    @token = MicroAuth::Token.find_by app: @app, code: params[:code]

    if @app.nil?
      render json: { error: { type: 'app_mismatch', message: 'No app found for this app_id and secret' } },
             status: 400
    elsif @token.nil?
      render json: { error: { type: 'token_mismatch', message: 'No token found for this app_id and code' } },
             status: 400
    elsif @token.code_expires_at.past?
      render json: { error: { type: 'code_expired' } }, status: 400
    elsif !@token.active?
      render json: { error: { type: 'token_expired' } }, status: 400
    else
      render json: { token: @token.token, expires_at: @token.expires_at,
                     user: helpers.authenticated_user_object(@token) }
    end
  end

  private

  def set_app
    @app = MicroAuth::App.find_by app_id: params[:app_id]
    not_found if @app.nil?
  end

  def clean_scope(scope)
    scope = scope.is_a?(Array) ? scope : [scope]
    scope.select do |s|
      helpers.valid_auth_scopes.keys.include? s
    end
  end
end
