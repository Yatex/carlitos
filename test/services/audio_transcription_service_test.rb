require "test_helper"

class AudioTranscriptionServiceTest < ActiveSupport::TestCase
  class FakeTwilioClient
    def download_media(_url)
      { ok: true, status: 200, body: "audio-bytes", content_type: "audio/ogg" }
    end
  end

  test "returns a safe error when OpenAI credentials are missing" do
    service = AudioTranscriptionService.new(api_key: nil, twilio_client: FakeTwilioClient.new)

    result = service.transcribe_twilio_media(
      "NumMedia" => "1",
      "MediaUrl0" => "https://api.twilio.com/media/test",
      "MediaContentType0" => "audio/ogg"
    )

    assert_equal false, result[:ok]
    assert_equal true, result[:audio_present]
    assert result[:error].present?
  end
end
