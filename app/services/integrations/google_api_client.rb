require "json"
require "net/http"

module Integrations
  class GoogleApiClient
    TOKEN_URL = "https://oauth2.googleapis.com/token".freeze

    class Error < StandardError; end
    class MissingConnection < Error; end
    class MissingToken < Error; end

    def initialize(user:, provider:)
      @user = user
      @provider = provider
      @connection = user.integration_connections.find_by(provider: provider, status: "connected")
    end

    def get(url, params: {})
      request(:get, url, params: params)
    end

    def post_json(url, payload)
      request(:post, url, json: payload)
    end

    private

    attr_reader :connection

    def request(method, url, params: {}, json: nil, retry_on_unauthorized: true)
      ensure_access_token!

      uri = URI(url)
      uri.query = [uri.query, URI.encode_www_form(params)].compact_blank.join("&") if params.present?
      request = method == :get ? Net::HTTP::Get.new(uri) : Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{Integrations::GoogleTokenStore.access_token(connection)}"
      request["Content-Type"] = "application/json" if json
      request.body = json.to_json if json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
      if response.code.to_i == 401 && retry_on_unauthorized && refresh_access_token
        return request(method, url, params: params, json: json, retry_on_unauthorized: false)
      end

      body = JSON.parse(response.body.presence || "{}")
      raise Error, body.dig("error", "message") || "Google API responded #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      body
    rescue JSON::ParserError
      raise Error, "Google API returned an invalid response"
    end

    def ensure_access_token!
      raise MissingConnection, "Connect #{@provider} first" unless connection

      refresh_access_token if token_expired?
      raise MissingToken, "Reconnect #{@provider} to grant access" if Integrations::GoogleTokenStore.access_token(connection).blank?
    end

    def token_expired?
      expires_at = connection.metadata["expires_at"].presence
      return false unless expires_at

      Time.zone.parse(expires_at) <= 2.minutes.from_now
    rescue ArgumentError
      true
    end

    def refresh_access_token
      refresh_token = Integrations::GoogleTokenStore.refresh_token(connection)
      return false if refresh_token.blank?

      uri = URI(TOKEN_URL)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(
        client_id: ENV["GOOGLE_CLIENT_ID"],
        client_secret: ENV["GOOGLE_CLIENT_SECRET"],
        refresh_token: refresh_token,
        grant_type: "refresh_token"
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
      body = JSON.parse(response.body.presence || "{}")
      return false unless response.is_a?(Net::HTTPSuccess)

      Integrations::GoogleTokenStore.update_from_token_response!(connection, body)
      true
    rescue StandardError => e
      Rails.logger.warn("[Google API] Token refresh failed: #{e.class} #{e.message}")
      false
    end
  end
end
