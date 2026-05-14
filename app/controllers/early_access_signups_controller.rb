class EarlyAccessSignupsController < ApplicationController
  def create
    @early_access_signup = EarlyAccessSignup.new(early_access_signup_params)

    if @early_access_signup.save
      TransactionalEmail.early_access_confirmation(@early_access_signup)
      redirect_to root_path(anchor: "early-access"), notice: t("flash.early_access.success")
    else
      flash.now[:alert] = t("flash.early_access.invalid")
      render "home/index", status: :unprocessable_entity
    end
  end

  private

  def early_access_signup_params
    params.require(:early_access_signup).permit(:name, :email)
  end
end
