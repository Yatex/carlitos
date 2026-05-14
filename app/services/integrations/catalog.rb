module Integrations
  class Catalog
    PROVIDERS = {
      "gmail" => {
        scopes: [
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.send"
        ],
        env: %w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET]
      },
      "google_calendar" => {
        scopes: [
          "https://www.googleapis.com/auth/calendar.readonly",
          "https://www.googleapis.com/auth/calendar.events"
        ],
        env: %w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET]
      },
      "whatsapp" => {
        scopes: [],
        env: %w[TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN TWILIO_WHATSAPP_FROM]
      }
    }.freeze

    class << self
      def fetch(provider)
        config = PROVIDERS.fetch(provider)
        config.merge(
          name: I18n.t("settings.integrations.#{provider}.name"),
          short_name: I18n.t("settings.integrations.#{provider}.short_name"),
          summary: I18n.t("settings.integrations.#{provider}.summary"),
          value: I18n.t("settings.integrations.#{provider}.value")
        )
      end

      def providers
        PROVIDERS.keys
      end

      def cards_for(user)
        providers.map do |provider|
          config = fetch(provider)
          connection = user.integration_connections.find_or_initialize_by(provider: provider)
          config.merge(provider: provider, connection: connection, configured: configured?(config))
        end
      end

      def configured?(config)
        config[:env].all? { |key| ENV[key].present? }
      end
    end
  end
end
