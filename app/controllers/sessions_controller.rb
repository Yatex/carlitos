class SessionsController < ApplicationController
  before_action :redirect_authenticated_user!, only: [:new]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_to dashboard_path, notice: "Sesión iniciada."
    else
      flash.now[:alert] = "Email o contraseña incorrectos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: "Sesión cerrada."
  end
end
