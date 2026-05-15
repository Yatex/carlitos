require "test_helper"

class WhatsappInboundProcessorTest < ActiveSupport::TestCase
  class FakeTranscriptionService
    def initialize(result)
      @result = result
    end

    def transcribe_twilio_media(_payload)
      @result
    end
  end

  test "transcribed WhatsApp voice note is processed by the assistant" do
    user = users(:one)
    user.integration_connections.create!(
      provider: "whatsapp",
      status: "connected",
      display_name: "+59899999999"
    )

    processor = WhatsappInboundProcessor.new(
      {
        "From" => "whatsapp:+59899999999",
        "Body" => "",
        "NumMedia" => "1",
        "MediaContentType0" => "audio/ogg",
        "MediaUrl0" => "https://api.twilio.com/media/test",
        "MessageSid" => "SM123"
      },
      transcription_service: FakeTranscriptionService.new(
        ok: true,
        audio_present: true,
        text: "guardá que mi DNI vence en agosto",
        metadata: { transcription_model: "test" }
      )
    )

    assert_difference("MemoryNote.count", 1) do
      result = processor.process
      assert_match "guardé", result[:response]
    end

    assert_equal "guardá que mi DNI vence en agosto", user.assistant_messages.order(:id).last(2).first.body
  end

  test "untranscribed WhatsApp voice note returns a helpful message" do
    user = users(:one)
    user.integration_connections.create!(
      provider: "whatsapp",
      status: "connected",
      display_name: "+59888888888"
    )

    processor = WhatsappInboundProcessor.new(
      {
        "From" => "whatsapp:+59888888888",
        "Body" => "",
        "NumMedia" => "1",
        "MediaContentType0" => "audio/ogg",
        "MediaUrl0" => "https://api.twilio.com/media/test"
      },
      transcription_service: FakeTranscriptionService.new(
        ok: false,
        audio_present: true,
        error: "missing key",
        metadata: {}
      )
    )

    assert_no_difference("MemoryNote.count") do
      result = processor.process
      assert_match "audio", result[:response]
    end
  end
end
