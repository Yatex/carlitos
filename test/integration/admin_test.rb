require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  test "normal users cannot access admin sections" do
    sign_in_as users(:one)

    get admin_users_path

    assert_redirected_to dashboard_path
  end

  test "admins can see users and analytics sections" do
    sign_in_as users(:admin)

    get admin_users_path
    assert_response :success
    assert_includes response.body, "Usuarios y planes"

    get admin_analytics_path
    assert_response :success
    assert_includes response.body, "Estadísticas generales"
    assert_includes response.body, "Pagando planes"
  end

  test "admin can extend a user plan" do
    sign_in_as users(:admin)
    target = users(:one)
    end_date = 45.days.from_now.to_date

    patch extend_plan_admin_user_path(target), params: {
      current_plan: "pro",
      plan_expires_on: end_date
    }

    assert_redirected_to admin_users_path
    target.reload
    assert_equal "pro", target.current_plan
    assert_equal "active", target.subscription_status
    assert_equal users(:admin), target.plan_granted_by
    assert_equal end_date, target.plan_expires_at.to_date
  end

  test "super admin can update another user role" do
    sign_in_as users(:admin)
    target = users(:two)

    patch update_role_admin_user_path(target), params: { role: "admin" }

    assert_redirected_to admin_users_path
    assert_equal "admin", target.reload.role
  end
end
