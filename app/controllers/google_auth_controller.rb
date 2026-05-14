class GoogleAuthController < ApplicationController
  before_action :redirect_authenticated_user!, only: :start

  def start
    service = Authentication::GoogleOauthService.new

    unless service.configured?
      redirect_to fallback_path, alert: t("flash.google_auth.not_configured")
      return
    end

    redirect_to service.authorization_url(
      callback_url: google_auth_callback_url,
      intent: params[:intent],
      timezone: params[:timezone]
    ), allow_other_host: true
  end

  def callback
    state = Authentication::GoogleOauthService.decode_state(params[:state])&.with_indifferent_access
    unless Authentication::GoogleOauthService.valid_state?(state)
      redirect_to login_path, alert: t("flash.google_auth.invalid_state")
      return
    end

    service = Authentication::GoogleOauthService.new
    token_result = service.exchange_code(params[:code], callback_url: google_auth_callback_url)
    unless token_result[:ok]
      redirect_to auth_failure_path(state), alert: t("flash.google_auth.login_failed", error: token_result[:error])
      return
    end

    profile_result = service.fetch_userinfo(token_result[:access_token])
    unless profile_result[:ok]
      redirect_to auth_failure_path(state), alert: t("flash.google_auth.profile_failed", error: profile_result[:error])
      return
    end

    result = Authentication::GoogleAccountProvisioner.new.call(
      profile: profile_result[:profile],
      timezone: state[:timezone]
    )

    sign_in(result.user)
    redirect_to dashboard_path, notice: result.created ? t("flash.google_auth.created") : t("flash.google_auth.signed_in")
  rescue Authentication::GoogleAccountProvisioner::ProvisionError, ActiveRecord::RecordInvalid => e
    redirect_to auth_failure_path(state), alert: e.message
  end

  private

  def fallback_path
    params[:intent].to_s == "signup" ? signup_path : login_path
  end

  def auth_failure_path(state)
    state&.dig(:intent).to_s == "signup" ? signup_path : login_path
  end
end
