require "test_helper"

class BillingTest < ActionDispatch::IntegrationTest
  test "billing page shows tiered Carlitos plans" do
    sign_in_as users(:one)

    get billing_path

    assert_response :success
    assert_includes response.body, "Free"
    assert_includes response.body, "Pro"
    assert_includes response.body, "Family / Team"
    assert_includes response.body, "Recordatorios ilimitados"
    assert_includes response.body, "Contexto desde Gmail"
  end
end
