require "json"

module Integrations
  class GoogleTokenStore
    TOKEN_KEYS = %w[access_token refresh_token id_token].freeze

    class << self
      def metadata_from_token_response(provider, token_response)
        token_payload = token_response.slice(*TOKEN_KEYS)
        {
          "provider" => provider,
          "scopes" => token_response["scope"].to_s.split(/\s+/),
          "token_type" => token_response["token_type"],
          "expires_at" => token_response["expires_in"].present? ? token_response["expires_in"].to_i.seconds.from_now.iso8601 : nil,
          "token_received_at" => Time.current.iso8601,
          "token_storage" => token_payload.any? ? "encrypted_metadata" : "missing",
          "tokens" => token_payload.any? ? encrypt(token_payload) : nil
        }.compact
      end

      def tokens(connection)
        encrypted = connection.metadata["tokens"]
        return {} if encrypted.blank?

        JSON.parse(encryptor.decrypt_and_verify(encrypted))
      rescue ActiveSupport::MessageEncryptor::InvalidMessage, JSON::ParserError
        {}
      end

      def access_token(connection)
        tokens(connection)["access_token"]
      end

      def refresh_token(connection)
        tokens(connection)["refresh_token"]
      end

      def update_from_token_response!(connection, token_response)
        merged_tokens = tokens(connection).merge(token_response.slice(*TOKEN_KEYS).compact)
        metadata = connection.metadata.merge(
          "token_type" => token_response["token_type"].presence || connection.metadata["token_type"],
          "expires_at" => token_response["expires_in"].present? ? token_response["expires_in"].to_i.seconds.from_now.iso8601 : connection.metadata["expires_at"],
          "token_received_at" => Time.current.iso8601,
          "token_storage" => "encrypted_metadata",
          "tokens" => encrypt(merged_tokens)
        ).compact

        connection.update!(metadata: metadata)
      end

      private

      def encrypt(payload)
        encryptor.encrypt_and_sign(payload.to_json)
      end

      def encryptor
        key = Rails.application.key_generator.generate_key(
          "carlitos-google-integration-tokens",
          ActiveSupport::MessageEncryptor.key_len
        )
        ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm")
      end
    end
  end
end
