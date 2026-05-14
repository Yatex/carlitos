class WhatsappInboundProcessor
  def initialize(payload, decision_service: Assistant::DecisionService.new)
    @payload = payload
    @decision_service = decision_service
  end

  def process
    user = resolve_user
    return { response: I18n.t("whatsapp.inbound.unlinked") } unless user

    body = @payload["Body"].to_s.strip
    user.assistant_messages.create!(
      direction: "inbound",
      channel: "whatsapp",
      body: body,
      metadata: { from: @payload["From"], message_sid: @payload["MessageSid"] }.compact
    )

    decision = @decision_service.call(user:, input: body, channel: "whatsapp")
    result = Assistant::ActionDispatcher.new(user:, decision:).call

    user.assistant_messages.create!(
      direction: "outbound",
      channel: "whatsapp",
      body: result.message,
      metadata: { action: decision.action, confidence: decision.confidence }
    )

    { response: result.message }
  rescue StandardError => e
    Rails.logger.warn("[WhatsApp] Inbound processing failed: #{e.class} #{e.message}")
    { response: I18n.t("whatsapp.inbound.failed") }
  end

  private

  def resolve_user
    explicit_user ||
      user_from_whatsapp_connection
  end

  def explicit_user
    User.find_by(id: @payload["user_id"]) ||
      User.find_by(email: @payload["email"].to_s.strip.downcase)
  end

  def user_from_whatsapp_connection
    from = @payload["From"].to_s.delete_prefix("whatsapp:")
    return if from.blank?

    connection = IntegrationConnection.find_by(provider: "whatsapp", display_name: from) ||
      IntegrationConnection.where(provider: "whatsapp").find_by("metadata ->> 'phone' = ?", from)
    return unless connection

    connection.update!(
      status: "connected",
      connected_at: connection.connected_at || Time.current,
      metadata: connection.metadata.merge("last_inbound_from" => from)
    )
    connection.user
  end
end
