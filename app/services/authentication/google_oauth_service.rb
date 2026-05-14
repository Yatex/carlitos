require "net/http"
require "json"

module Authentication
  class GoogleOauthService
    AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth".freeze
    TOKEN_URL = "https://oauth2.googleapis.com/token".freeze
    USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo".freeze
    DEFAULT_SCOPES = %w[openid email profile].freeze
    VALID_INTENTS = %w[login signup].freeze

    def configured?
      ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
    end

    def authorization_url(callback_url:, intent:, timezone: nil)
      uri = URI(AUTH_URL)
      uri.query = URI.encode_www_form(
        client_id: ENV["GOOGLE_CLIENT_ID"],
        redirect_uri: redirect_uri(callback_url),
        response_type: "code",
        scope: scopes.join(" "),
        prompt: "select_account",
        state: self.class.encode_state(intent: intent, timezone: timezone)
      )
      uri.to_s
    end

    def exchange_code(code, callback_url:)
      return { ok: false, error: I18n.t("auth_services.google.not_configured") } unless configured?

      uri = URI(TOKEN_URL)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(
        code: code,
        client_id: ENV["GOOGLE_CLIENT_ID"],
        client_secret: ENV["GOOGLE_CLIENT_SECRET"],
        redirect_uri: redirect_uri(callback_url),
        grant_type: "authorization_code"
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
      body = JSON.parse(response.body.presence || "{}")

      if response.is_a?(Net::HTTPSuccess)
        { ok: true, access_token: body["access_token"], token_response: body }
      else
        { ok: false, error: body.dig("error_description") || body["error"] || I18n.t("auth_services.google.response", code: response.code) }
      end
    rescue StandardError => e
      Rails.logger.warn("[Google Auth] Token exchange failed: #{e.class} #{e.message}")
      { ok: false, error: e.message }
    end

    def fetch_userinfo(access_token)
      return { ok: false, error: I18n.t("auth_services.google.missing_token") } if access_token.blank?

      uri = URI(USERINFO_URL)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{access_token}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
      body = JSON.parse(response.body.presence || "{}")

      if response.is_a?(Net::HTTPSuccess)
        { ok: true, profile: body }
      else
        { ok: false, error: body["error_description"] || body["error"] || I18n.t("auth_services.google.userinfo_response", code: response.code) }
      end
    rescue StandardError => e
      Rails.logger.warn("[Google Auth] Userinfo failed: #{e.class} #{e.message}")
      { ok: false, error: e.message }
    end

    def scopes
      ENV["GOOGLE_AUTH_SCOPES"].presence&.split(/\s+/) || DEFAULT_SCOPES
    end

    def self.encode_state(intent:, timezone: nil)
      verifier.generate({
        intent: VALID_INTENTS.include?(intent.to_s) ? intent.to_s : "login",
        timezone: timezone.presence,
        issued_at: Time.current.to_i
      })
    end

    def self.decode_state(state)
      verifier.verify(state)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def self.valid_state?(state)
      state.present? && Time.zone.at(state["issued_at"].to_i) > 15.minutes.ago
    end

    def self.verifier
      Rails.application.message_verifier(:google_auth)
    end

    private

    def redirect_uri(callback_url)
      ENV["GOOGLE_AUTH_REDIRECT_URI"].presence || callback_url
    end
  end
end
