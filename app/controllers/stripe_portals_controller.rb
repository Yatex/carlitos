class StripePortalsController < ApplicationController
  before_action :authenticate_user!

  def create
    session = StripeClient.new.create_customer_portal_session(user: current_user, return_url: billing_url)

    if session[:url].present?
      redirect_to session[:url], allow_other_host: true
    else
      redirect_to billing_path, alert: session[:error] || "No pudimos abrir el portal de facturación."
    end
  end
end
