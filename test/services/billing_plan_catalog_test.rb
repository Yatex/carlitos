require "test_helper"

class BillingPlanCatalogTest < ActiveSupport::TestCase
  test "finds checkoutable paid plans by key" do
    plan = Billing::PlanCatalog.find!("pro")

    assert_equal "Pro", plan.name
    assert plan.checkoutable?
    assert_equal "STRIPE_PRICE_PRO", plan.stripe_price_env
  end

  test "free plan is not sent to Stripe checkout" do
    plan = Billing::PlanCatalog.find!("free")

    assert_not plan.paid?
    assert_not plan.checkoutable?
  end
end
