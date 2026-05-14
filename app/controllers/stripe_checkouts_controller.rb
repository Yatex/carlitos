class StripeCheckoutsController < ApplicationController
  before_action :authenticate_user!

  def create
    plan = params[:plan].presence || "pro"
    session = StripeClient.new.create_checkout_session(
      user: current_user,
      plan: plan,
      success_url: billing_url(checkout: "success"),
      cancel_url: billing_url(checkout: "cancelled")
    )

    if session[:url].present?
      redirect_to session[:url], allow_other_host: true
    else
      redirect_to billing_path, alert: session[:error] || t("flash.stripe.checkout_failed")
    end
  end
end
