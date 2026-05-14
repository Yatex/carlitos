class ApplicationController < ActionController::Base
  before_action :set_locale
  around_action :use_user_time_zone

  helper_method :current_user, :authenticated?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def authenticated?
    current_user.present?
  end

  def authenticate_user!
    return if authenticated?

    redirect_to login_path, alert: t("flash.auth.required")
  end

  def redirect_authenticated_user!
    redirect_to dashboard_path if authenticated?
  end

  def sign_in(user)
    locale = session[:locale]
    reset_session
    session[:user_id] = user.id
    session[:locale] = locale if locale.present?
  end

  def sign_out
    locale = session[:locale]
    reset_session
    session[:locale] = locale if locale.present?
  end

  def use_user_time_zone(&block)
    Time.use_zone(current_user&.timezone || Rails.application.config.time_zone, &block)
  end

  def set_locale
    session[:locale] = params[:locale] if params[:locale].in?(I18n.available_locales.map(&:to_s))
    I18n.locale = session[:locale].presence || I18n.default_locale
  end
end
