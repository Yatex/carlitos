class WhatsappOutboundMessageService
  def initialize(client: TwilioClient.new)
    @client = client
  end

  def deliver(user:, to:, body:, metadata: {})
    user.assistant_messages.create!(
      direction: "outbound",
      channel: "whatsapp",
      body: body,
      metadata: metadata
    )
    @client.send_whatsapp(to:, body:)
  end
end
