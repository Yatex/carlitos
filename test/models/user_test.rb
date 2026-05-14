require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "new users start with a 14 day free trial" do
    user = User.create!(
      name: "Trial User",
      email: "trial-user@example.com",
      timezone: "America/Montevideo",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_equal "free", user.current_plan
    assert_equal "trialing", user.subscription_status
    assert user.free_trial_active?
    assert_in_delta 14.days.from_now.to_i, user.free_trial_ends_at.to_i, 5
    assert_equal user.free_trial_ends_at.to_i, user.plan_expires_at.to_i
  end

  test "paid users created directly do not receive a free trial" do
    user = User.create!(
      name: "Paid User",
      email: "paid-user@example.com",
      timezone: "America/Montevideo",
      current_plan: "pro",
      subscription_status: "active",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_nil user.free_trial_started_at
    assert_nil user.free_trial_ends_at
    assert_equal "pro", user.current_plan
  end
end
