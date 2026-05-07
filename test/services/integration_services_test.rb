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
end
