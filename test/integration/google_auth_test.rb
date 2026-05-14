require "test_helper"
require "minitest/mock"

class GoogleAuthTest < ActionDispatch::IntegrationTest
  FakeGoogleService = Struct.new(:profile) do
    def exchange_code(_code, callback_url:)
      { ok: true, access_token: "access-token", token_response: { "access_token" => "access-token" } }
    end

    def fetch_userinfo(_access_token)
      { ok: true, profile: profile }
    end
  end

  test "google auth start fails gracefully without credentials" do
    old_client_id = ENV.delete("GOOGLE_CLIENT_ID")
    old_client_secret = ENV.delete("GOOGLE_CLIENT_SECRET")

    get google_auth_path(intent: "login")

    assert_redirected_to login_path
    assert_equal I18n.t("flash.google_auth.not_configured", locale: :es), flash[:alert]
  ensure
    ENV["GOOGLE_CLIENT_ID"] = old_client_id if old_client_id
    ENV["GOOGLE_CLIENT_SECRET"] = old_client_secret if old_client_secret
  end

  test "google callback creates a user and signs them in" do
    state = Authentication::GoogleOauthService.encode_state(intent: "signup", timezone: "America/Montevideo")
    profile = {
      "sub" => "google-123",
      "email" => "google-user@example.com",
      "email_verified" => true,
      "name" => "Google User"
    }

    assert_difference("User.count", 1) do
      Authentication::GoogleOauthService.stub(:new, FakeGoogleService.new(profile)) do
        get google_auth_callback_path, params: { code: "code", state: state }
      end
    end

    user = User.find_by!(email: "google-user@example.com")
    assert_redirected_to dashboard_path
    assert_equal user.id, session[:user_id]
    assert_equal "google-123", user.google_uid
    assert user.google_email_verified?
    assert_equal "trialing", user.subscription_status
    assert user.free_trial_active?
  end

  test "google callback links an existing email account" do
    state = Authentication::GoogleOauthService.encode_state(intent: "login", timezone: "America/Montevideo")
    existing = users(:one)
    profile = {
      "sub" => "google-existing",
      "email" => existing.email,
      "email_verified" => true,
      "name" => existing.name
    }

    assert_no_difference("User.count") do
      Authentication::GoogleOauthService.stub(:new, FakeGoogleService.new(profile)) do
        get google_auth_callback_path, params: { code: "code", state: state }
      end
    end

    assert_redirected_to dashboard_path
    assert_equal existing.id, session[:user_id]
    assert_equal "google-existing", existing.reload.google_uid
  end
end
