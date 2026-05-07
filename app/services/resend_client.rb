require "net/http"
require "json"

class ResendClient
  API_URL = "https://api.resend.com/emails".freeze

  def initialize(api_key: ENV["RESEND_API_KEY"], from_email: ENV["RESEND_FROM_EMAIL"])
    @api_key = api_key
    @from_email = from_email
  end

  def configured?
    @api_key.present? && @from_email.present?
  end

  def send_email(to:, subject:, html:, text:)
    unless configured?
      Rails.logger.warn("[Resend] RESEND_API_KEY or RESEND_FROM_EMAIL missing; skipped email to #{to}.")
      return { ok: false, error: "Resend is not configured" }
    end

    uri = URI(API_URL)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request.body = {
      from: @from_email,
      to: [to],
      subject:,
      html:,
      text:
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    { ok: response.is_a?(Net::HTTPSuccess), status: response.code.to_i, body: response.body }
  rescue StandardError => e
    Rails.logger.warn("[Resend] Email delivery failed: #{e.class} #{e.message}")
    { ok: false, error: e.message }
  end
end
