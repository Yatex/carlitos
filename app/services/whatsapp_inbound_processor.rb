class WhatsappInboundProcessor
  def initialize(payload, decision_service: Assistant::DecisionService.new, transcription_service: AudioTranscriptionService.new)
    @payload = payload
    @decision_service = decision_service
    @transcription_service = transcription_service
  end

  def process
    user = resolve_user
    return { response: I18n.t("whatsapp.inbound.unlinked") } unless user

    body = @payload["Body"].to_s.strip
    transcription = transcribe_audio
    input = assistant_input(body, transcription)

    user.assistant_messages.create!(
      direction: "inbound",
      channel: "whatsapp",
      body: input.presence || inbound_placeholder(transcription),
      metadata: inbound_metadata(transcription)
    )

    if input.blank?
      response = transcription[:audio_present] ? I18n.t("whatsapp.inbound.audio_unavailable") : I18n.t("whatsapp.inbound.empty")
      user.assistant_messages.create!(
        direction: "outbound",
        channel: "whatsapp",
        body: response,
        metadata: { action: "unknown", reason: "empty_input" }
      )
      return { response: response }
    end

    decision = @decision_service.call(user:, input: input, channel: "whatsapp")
    result = Assistant::ActionDispatcher.new(user:, decision:).call

    user.assistant_messages.create!(
      direction: "outbound",
      channel: "whatsapp",
      body: result.message,
      metadata: { action: decision.action, confidence: decision.confidence, audio_transcribed: transcription[:ok] == true }
    )

    { response: result.message }
  rescue StandardError => e
    Rails.logger.warn("[WhatsApp] Inbound processing failed: #{e.class} #{e.message}")
    { response: I18n.t("whatsapp.inbound.failed") }
  end

  private

  def transcribe_audio
    @transcription_service.transcribe_twilio_media(@payload)
  rescue StandardError => e
    Rails.logger.warn("[WhatsApp] Audio transcription failed: #{e.class} #{e.message}")
    { ok: false, audio_present: has_audio_media?, error: e.message, metadata: {} }
  end

  def assistant_input(body, transcription)
    [body.presence, transcription[:text].presence].compact.join("\n\n").strip
  end

  def inbound_placeholder(transcription)
    transcription[:audio_present] ? I18n.t("whatsapp.inbound.audio_placeholder") : I18n.t("whatsapp.inbound.empty_placeholder")
  end

  def inbound_metadata(transcription)
    {
      from: @payload["From"],
      message_sid: @payload["MessageSid"],
      media_count: @payload["NumMedia"].to_i,
      audio_transcribed: transcription[:ok] == true,
      transcription_error: transcription[:error],
      transcription: transcription[:metadata]
    }.compact
  end

  def has_audio_media?
    count = @payload["NumMedia"].to_i
    (0...count).any? { |index| @payload["MediaContentType#{index}"].to_s.start_with?("audio/") }
  end

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
