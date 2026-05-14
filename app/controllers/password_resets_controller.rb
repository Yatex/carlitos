class PasswordResetsController < ApplicationController
  before_action :set_user_from_token, only: [:edit, :update]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user
      user.prepare_password_reset!
      TransactionalEmail.password_reset(user, edit_password_reset_url(user.password_reset_token))
    end

    redirect_to login_path, notice: t("flash.password_resets.sent")
  end

  def edit
    redirect_to new_password_reset_path, alert: t("flash.password_resets.expired") if @user.password_reset_expired?
  end

  def update
    if @user.password_reset_expired?
      redirect_to new_password_reset_path, alert: t("flash.password_resets.expired")
    elsif @user.update(password_params.merge(password_reset_sent_at: nil))
      @user.regenerate_password_reset_token
      redirect_to login_path, notice: t("flash.password_resets.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_from_token
    @user = User.find_by!(password_reset_token: params[:token])
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
