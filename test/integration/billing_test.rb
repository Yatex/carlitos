require "test_helper"

class BillingTest < ActionDispatch::IntegrationTest
  test "billing page shows tiered Carlitos plans" do
    sign_in_as users(:one)

    get billing_path

    assert_response :success
    assert_includes response.body, "Prueba Pro"
    assert_includes response.body, "Pro"
    assert_includes response.body, "Familia"
    assert_includes response.body, "USD 15/mes"
    assert_includes response.body, "USD 39/mes"
    assert_includes response.body, "Hasta 5 personas"
    assert_includes response.body, "Recordatorios inteligentes"
    assert_includes response.body, "Gmail y calendario"
  end
end
