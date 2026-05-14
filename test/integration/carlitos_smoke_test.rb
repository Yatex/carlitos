require "test_helper"

class CarlitosSmokeTest < ActionDispatch::IntegrationTest
  test "root page loads" do
    get root_path
    assert_response :success
    assert_includes response.body, "Carlitos se acuerda por vos."
  end

  test "early access signup creates a record" do
    assert_difference("EarlyAccessSignup.count", 1) do
      post early_access_signups_path, params: {
        early_access_signup: { name: "Sofía", email: "sofia@example.com" }
      }
    end

    assert_redirected_to root_path(anchor: "early-access")
  end

  test "user can sign up and lands on dashboard" do
    assert_difference("User.count", 1) do
      post signup_path, params: {
        user: {
          name: "Clara",
          email: "clara@example.com",
          timezone: "America/Montevideo",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to dashboard_path
    user = User.find_by!(email: "clara@example.com")
    assert_equal "free", user.current_plan
    assert_equal "trialing", user.subscription_status
    assert user.free_trial_active?
  end

  test "user can log in" do
    sign_in_as users(:one)
    assert_redirected_to dashboard_path
  end

  test "dashboard requires authentication" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "logged in user can create reminder" do
    sign_in_as users(:one)

    assert_difference("Reminder.count", 1) do
      post reminders_path, params: {
        reminder: {
          title: "Pagar alquiler",
          body: "Transferir antes del viernes",
          remind_at: 1.day.from_now,
          status: "pending"
        }
      }
    end
  end

  test "logged in user can create memory note" do
    sign_in_as users(:one)

    assert_difference("MemoryNote.count", 1) do
      post memory_notes_path, params: {
        memory_note: {
          title: "DNI",
          content: "Mi DNI vence en agosto"
        }
      }
    end
  end

  test "stripe webhook endpoint exists" do
    post stripe_webhooks_path,
      params: { type: "ping", data: { object: {} } }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success
  end

  test "whatsapp webhook endpoint exists" do
    post whatsapp_inbound_path, params: {
      "From" => "whatsapp:+59899999999",
      "Body" => "hola"
    }

    assert_response :success
    assert_includes response.body, "vincular"
  end
end
