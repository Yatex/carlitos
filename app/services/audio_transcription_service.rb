require "json"
require "net/http"
require "tempfile"

class AudioTranscriptionService
  TRANSCRIPTIONS_URL = "https://api.openai.com/v1/audio/transcriptions".freeze
  DEFAULT_MODEL = "gpt-4o-mini-transcribe".freeze
  DEFAULT_MAX_BYTES = 25 * 1024 * 1024

  def initialize(
    api_key: ENV["OPENAI_API_KEY"],
    model: ENV["OPENAI_TRANSCRIPTION_MODEL"].presence || DEFAULT_MODEL,
    language: ENV["OPENAI_TRANSCRIPTION_LANGUAGE"],
    twilio_client: TwilioClient.new
  )
    @api_key = api_key
    @model = model
    @language = language
    @twilio_client = twilio_client
  end

  def configured?
    @api_key.present?
  end

  def transcribe_twilio_media(payload)
    media = audio_media(payload).first
    return { ok: false, audio_present: false, skipped: true } unless media

    unless configured?
      Rails.logger.warn("[AudioTranscription] OPENAI_API_KEY missing; skipped transcription.")
      return failure(error: I18n.t("audio_transcription.errors.not_configured"), metadata: media_metadata(media))
    end

    download = @twilio_client.download_media(media[:url])
    unless download[:ok]
      return failure(
        error: download[:error] || I18n.t("audio_transcription.errors.download_failed"),
        metadata: media_metadata(media, download)
      )
    end

    transcribe_bytes(
      bytes: download[:body].to_s,
      content_type: download[:content_type].presence || media[:content_type],
      filename: "whatsapp-audio-#{media[:index]}#{extension_for(download[:content_type].presence || media[:content_type])}",
      metadata: media_metadata(media, download)
    )
  end

  private

  def audio_media(payload)
    count = payload["NumMedia"].to_i
    (0...count).filter_map do |index|
      content_type = payload["MediaContentType#{index}"].to_s
      next unless content_type.start_with?("audio/")

      url = payload["MediaUrl#{index}"].to_s
      next if url.blank?

      { index:, url:, content_type: }
    end
  end

  def transcribe_bytes(bytes:, content_type:, filename:, metadata:)
    if bytes.bytesize > max_bytes
      return failure(error: I18n.t("audio_transcription.errors.too_large"), metadata: metadata.merge(bytes: bytes.bytesize))
    end

    file = Tempfile.new(["carlitos-whatsapp-audio", File.extname(filename)])
    file.binmode
    file.write(bytes)
    file.rewind

    request = Net::HTTP::Post.new(URI(TRANSCRIPTIONS_URL))
    request["Authorization"] = "Bearer #{@api_key}"
    request.set_form(
      multipart_fields(file:, filename:, content_type:),
      "multipart/form-data"
    )

    uri = URI(TRANSCRIPTIONS_URL)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    parsed = JSON.parse(response.body.presence || "{}")
    unless response.is_a?(Net::HTTPSuccess)
      return failure(error: parsed.dig("error", "message") || I18n.t("audio_transcription.errors.response", code: response.code), metadata:)
    end

    text = parsed["text"].to_s.strip
    return failure(error: I18n.t("audio_transcription.errors.blank"), metadata:) if text.blank?

    {
      ok: true,
      audio_present: true,
      text: text,
      metadata: metadata.merge(
        transcription_model: @model,
        transcription_language: @language.presence,
        transcript_length: text.length
      ).compact
    }
  rescue JSON::ParserError
    failure(error: I18n.t("audio_transcription.errors.invalid_response"), metadata:)
  rescue StandardError => e
    Rails.logger.warn("[AudioTranscription] Failed: #{e.class} #{e.message}")
    failure(error: e.message, metadata:)
  ensure
    file&.close!
  end

  def multipart_fields(file:, filename:, content_type:)
    fields = [
      ["model", @model],
      ["file", file, { filename:, content_type: content_type.presence || "audio/ogg" }],
      ["response_format", "json"]
    ]
    fields << ["language", @language] if @language.present?
    fields
  end

  def failure(error:, metadata:)
    {
      ok: false,
      audio_present: true,
      error: error,
      metadata: metadata
    }
  end

  def media_metadata(media, download = {})
    {
      media_index: media[:index],
      media_content_type: media[:content_type],
      downloaded_content_type: download[:content_type],
      download_status: download[:status],
      bytes: download[:body].to_s.bytesize.presence
    }.compact
  end

  def max_bytes
    ENV["OPENAI_TRANSCRIPTION_MAX_BYTES"].presence&.to_i || DEFAULT_MAX_BYTES
  end

  def extension_for(content_type)
    case content_type.to_s.split(";").first
    when "audio/mpeg", "audio/mp3" then ".mp3"
    when "audio/mp4" then ".mp4"
    when "audio/mpga" then ".mpga"
    when "audio/m4a", "audio/x-m4a" then ".m4a"
    when "audio/wav", "audio/x-wav" then ".wav"
    when "audio/webm" then ".webm"
    when "audio/ogg", "audio/opus" then ".ogg"
    else ".ogg"
    end
  end
end
