require "test_helper"

class IntegrationServicesTest < ActiveSupport::TestCase
  test "resend client initializes safely without credentials" do
    client = ResendClient.new(api_key: nil, from_email: nil)
    result = client.send_email(to: "test@example.com", subject: "Hola", html: "<p>Hola</p>", text: "Hola")

    assert_not client.configured?
    assert_equal false, result[:ok]
  end

  test "assistant fallback can create a simple reminder" do
    user = users(:one)
    decision = Assistant::DecisionService.new(provider: nil, service_url: nil).call(
      user: user,
      input: "recordame pagar el alquiler mañana a las 10",
      channel: "web"
    )

    assert_equal "create_reminder", decision.action
    assert_difference("Reminder.count", 1) do
      result = Assistant::ActionDispatcher.new(user: user, decision: decision).call
      assert result.success?
    end
  end

  test "assistant fallback can save a memory note" do
    user = users(:one)
    decision = Assistant::DecisionService.new(provider: nil, service_url: nil).call(
      user: user,
      input: "guardá que mi DNI vence en agosto",
      channel: "web"
    )

    assert_equal "save_memory_note", decision.action
    assert_difference("MemoryNote.count", 1) do
      result = Assistant::ActionDispatcher.new(user: user, decision: decision).call
      assert result.success?
    end
  end

  test "assistant fallback can decide to search Gmail" do
    user = users(:one)
    decision = Assistant::DecisionService.new(provider: nil, service_url: nil).call(
      user: user,
      input: "revisá mis mails sobre factura de Stripe",
      channel: "whatsapp"
    )

    assert_equal "search_gmail", decision.action
    assert_equal "factura de Stripe", decision.arguments["query"]

    result = Assistant::ActionDispatcher.new(user: user, decision: decision).call
    assert_not result.success?
    assert_match "Gmail", result.message
  end

  test "assistant fallback can decide to create a calendar event" do
    user = users(:one)
    decision = Assistant::DecisionService.new(provider: nil, service_url: nil).call(
      user: user,
      input: "agendá reunión con Juan mañana a las 15",
      channel: "whatsapp"
    )

    assert_equal "create_calendar_event", decision.action
    assert_equal "Reunión con Juan", decision.arguments["title"]
    assert decision.arguments["starts_at"].present?
  end

  test "google token store encrypts and reads tokens" do
    user = users(:one)
    metadata = Integrations::GoogleTokenStore.metadata_from_token_response(
      "gmail",
      {
        "access_token" => "access-test",
        "refresh_token" => "refresh-test",
        "expires_in" => 3600,
        "scope" => "https://www.googleapis.com/auth/gmail.readonly",
        "token_type" => "Bearer"
      }
    )
    connection = user.integration_connections.create!(
      provider: "gmail",
      status: "connected",
      metadata: metadata
    )

    refute_includes metadata["tokens"], "access-test"
    assert_equal "access-test", Integrations::GoogleTokenStore.access_token(connection)
    assert_equal "refresh-test", Integrations::GoogleTokenStore.refresh_token(connection)
  end
end
