class ApplicationController < ActionController::Base
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

    redirect_to login_path, alert: "Iniciá sesión para continuar."
  end

  def redirect_authenticated_user!
    redirect_to dashboard_path if authenticated?
  end

  def sign_in(user)
    reset_session
    session[:user_id] = user.id
  end

  def sign_out
    reset_session
  end

  def use_user_time_zone(&block)
    Time.use_zone(current_user&.timezone || Rails.application.config.time_zone, &block)
  end
end
