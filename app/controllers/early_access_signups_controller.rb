class EarlyAccessSignupsController < ApplicationController
  def create
    @early_access_signup = EarlyAccessSignup.new(early_access_signup_params)

    if @early_access_signup.save
      TransactionalEmail.early_access_confirmation(@early_access_signup)
      redirect_to root_path(anchor: "early-access"), notice: "Listo. Te avisamos cuando Carlitos esté listo para probar."
    else
      flash.now[:alert] = "Revisá el email para sumarte al acceso anticipado."
      render "home/index", status: :unprocessable_entity
    end
  end

  private

  def early_access_signup_params
    params.require(:early_access_signup).permit(:name, :email)
  end
end
