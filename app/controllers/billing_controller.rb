class BillingController < ApplicationController
  before_action :authenticate_user!

  def show
    @plans = Billing::PlanCatalog.all
    @current_plan = Billing::PlanCatalog.current_for(current_user)
  end
end
