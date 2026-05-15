require "net/http"
require "json"

module Integrations
  class GoogleOauthService
    AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth".freeze
    TOKEN_URL = "https://oauth2.googleapis.com/token".freeze

    def initialize(user:, provider:)
      @user = user
      @provider = provider
      @config = Catalog.fetch(provider)
    end

    def configured?
      ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
    end

    def authorization_url(callback_url:)
      uri = URI(AUTH_URL)
      uri.query = URI.encode_www_form(
        client_id: ENV["GOOGLE_CLIENT_ID"],
        redirect_uri: redirect_uri(callback_url),
        response_type: "code",
        access_type: "offline",
        prompt: "consent",
        scope: scopes.join(" "),
        state: encode_state
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
        { ok: true, body: body }
      else
        { ok: false, error: body.dig("error_description") || body["error"] || I18n.t("auth_services.google.oauth_response", code: response.code) }
      end
    rescue StandardError => e
      Rails.logger.warn("[Google OAuth] Token exchange failed: #{e.class} #{e.message}")
      { ok: false, error: e.message }
    end

    def scopes
      env_key = @provider == "gmail" ? "GOOGLE_GMAIL_SCOPES" : "GOOGLE_CALENDAR_SCOPES"
      ENV[env_key].presence&.split(/\s+/) || @config[:scopes]
    end

    def encode_state
      verifier.generate(
        user_id: @user.id,
        provider: @provider,
        issued_at: Time.current.to_i
      )
    end

    def self.decode_state(state)
      Rails.application.message_verifier(:google_oauth).verify(state)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def self.metadata_from_token_response(provider, token_response)
      Integrations::GoogleTokenStore.metadata_from_token_response(provider, token_response)
    end

    private

    def redirect_uri(callback_url)
      ENV["GOOGLE_OAUTH_REDIRECT_URI"].presence || callback_url
    end

    def verifier
      Rails.application.message_verifier(:google_oauth)
    end
  end
end
