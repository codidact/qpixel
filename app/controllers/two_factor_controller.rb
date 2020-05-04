class TwoFactorController < ApplicationController
  before_action :authenticate_user!

  def tf_status; end

  def enable_2fa
    secret = ROTP::Base32.random
    current_user.update(two_factor_token: secret)
    totp = ROTP::TOTP.new(secret, issuer: 'codidact.com')
    uri = totp.provisioning_uri("#{current_user.id}@users-2fa.codidact.com")
    qr_svg = RQRCode::QRCode.new(uri).as_svg
    @qr_uri = "data:image/svg+xml;base64,#{Base64.encode64(qr_svg)}"
  end

  def enable_code; end

  def confirm_enable_code
    if current_user.two_factor_token.blank?
      flash[:danger] = "Missed a step! There's no 2FA token on your account."
      redirect_to two_factor_status_path && return
    end

    totp = ROTP::TOTP.new(current_user.two_factor_token)
    if totp.verify(params[:code], drift_behind: 15, drift_ahead: 15)
      current_user.update(enabled_2fa: true)
      flash[:success] = 'Success! 2FA has been enabled on your account.'
      redirect_to two_factor_status_path
    else
      flash[:danger] = "That's not the right code."
      redirect_to two_factor_enable_code_path
    end
  end

  def disable_code; end

  def confirm_disable_code
    if current_user.two_factor_token.blank?
      flash[:danger] = "I don't know how you got here, but something is badly wrong."
      redirect_to two_factor_status_path && return
    end

    totp = ROTP::TOTP.new(current_user.two_factor_token)
    if totp.verify(params[:code], drift_behind: 15, drift_ahead: 15)
      current_user.update(two_factor_token: nil, enabled_2fa: false)
      flash[:success] = 'Success! 2FA has been disabled on your account.'
      redirect_to two_factor_status_path
    else
      flash[:danger] = "That's not the right code."
      redirect_to two_factor_disable_code_path
    end
  end
end
