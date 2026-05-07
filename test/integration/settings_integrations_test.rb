require "test_helper"

class SettingsIntegrationsTest < ActionDispatch::IntegrationTest
  test "settings requires authentication" do
    get settings_path

    assert_redirected_to login_path
  end

  test "settings shows gmail calendar and whatsapp integrations" do
    sign_in_as users(:one)

    get settings_path

    assert_response :success
    assert_includes response.body, "Gmail"
    assert_includes response.body, "Google Calendar"
    assert_includes response.body, "WhatsApp"
  end

  test "connecting whatsapp saves pending connection when twilio is not configured" do
    old_twilio = %w[TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN TWILIO_WHATSAPP_FROM].index_with { |key| ENV.delete(key) }
    sign_in_as users(:one)

    assert_difference("IntegrationConnection.count", 1) do
      post connect_integration_path(provider: "whatsapp"), params: { phone: "+59899999999" }
    end

    connection = users(:one).integration_connections.find_by!(provider: "whatsapp")
    assert_equal "pending", connection.status
    assert_equal "+59899999999", connection.display_name
  ensure
    old_twilio&.each { |key, value| ENV[key] = value if value }
  end

  test "connecting gmail without google oauth credentials saves pending connection" do
    old_client_id = ENV.delete("GOOGLE_CLIENT_ID")
    old_client_secret = ENV.delete("GOOGLE_CLIENT_SECRET")
    sign_in_as users(:one)

    assert_difference("IntegrationConnection.count", 1) do
      post connect_integration_path(provider: "gmail")
    end

    connection = users(:one).integration_connections.find_by!(provider: "gmail")
    assert_equal "pending", connection.status
    assert_includes connection.metadata["missing_env"], "GOOGLE_CLIENT_ID"
  ensure
    ENV["GOOGLE_CLIENT_ID"] = old_client_id if old_client_id
    ENV["GOOGLE_CLIENT_SECRET"] = old_client_secret if old_client_secret
  end
end
