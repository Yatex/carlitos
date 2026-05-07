class AccountsController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  def update
    if current_user.update(account_params)
      redirect_to edit_account_path, notice: "Cuenta actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    permitted = params.require(:user).permit(:name, :email, :timezone, :password, :password_confirmation)
    return permitted if permitted[:password].present?

    permitted.except(:password, :password_confirmation)
  end
end
