require "net/http"

class TwilioClient
  API_BASE = "https://api.twilio.com/2010-04-01".freeze

  def initialize(
    account_sid: ENV["TWILIO_ACCOUNT_SID"],
    auth_token: ENV["TWILIO_AUTH_TOKEN"],
    whatsapp_from: ENV["TWILIO_WHATSAPP_FROM"]
  )
    @account_sid = account_sid
    @auth_token = auth_token
    @whatsapp_from = whatsapp_from
  end

  def configured?
    @account_sid.present? && @auth_token.present? && @whatsapp_from.present?
  end

  def send_whatsapp(to:, body:)
    unless configured?
      Rails.logger.warn("[Twilio] Credentials missing; skipped WhatsApp message to #{to}.")
      return { ok: false, error: "Twilio is not configured" }
    end

    uri = URI("#{API_BASE}/Accounts/#{@account_sid}/Messages.json")
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@account_sid, @auth_token)
    request.set_form_data(
      From: normalize_whatsapp(@whatsapp_from),
      To: normalize_whatsapp(to),
      Body: body
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    { ok: response.is_a?(Net::HTTPSuccess), status: response.code.to_i, body: response.body }
  rescue StandardError => e
    Rails.logger.warn("[Twilio] WhatsApp delivery failed: #{e.class} #{e.message}")
    { ok: false, error: e.message }
  end

  private

  def normalize_whatsapp(number)
    number.to_s.start_with?("whatsapp:") ? number : "whatsapp:#{number}"
  end
end
