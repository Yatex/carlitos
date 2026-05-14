class RegistrationsController < ApplicationController
  before_action :redirect_authenticated_user!, only: [:new]

  def new
    @user = User.new(timezone: "America/Montevideo")
  end

  def create
    @user = User.new(user_params)

    if @user.save
      sign_in(@user)
      TransactionalEmail.welcome(@user)
      redirect_to dashboard_path, notice: t("flash.registrations.welcome")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :timezone)
  end
end
