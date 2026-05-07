module Integrations
  class Catalog
    PROVIDERS = {
      "gmail" => {
        name: "Gmail",
        short_name: "Gmail",
        summary: "Carlitos puede usar mails autorizados como contexto para follow-ups, recordatorios y búsquedas.",
        value: "Detectar compromisos, datos importantes y pendientes que viven en tu inbox.",
        scopes: [
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.send"
        ],
        env: %w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET]
      },
      "google_calendar" => {
        name: "Google Calendar",
        short_name: "Calendar",
        summary: "Carlitos puede mirar tu agenda autorizada para briefings, reuniones y recordatorios con contexto.",
        value: "Entender qué tenés hoy y cuándo conviene avisarte.",
        scopes: [
          "https://www.googleapis.com/auth/calendar.readonly",
          "https://www.googleapis.com/auth/calendar.events"
        ],
        env: %w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET]
      },
      "whatsapp" => {
        name: "WhatsApp",
        short_name: "WhatsApp",
        summary: "El canal principal para mandarle mensajes, audios, listas y recordatorios a Carlitos.",
        value: "Capturar cosas en segundos desde donde ya hablás todos los días.",
        scopes: [],
        env: %w[TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN TWILIO_WHATSAPP_FROM]
      }
    }.freeze

    class << self
      def fetch(provider)
        PROVIDERS.fetch(provider)
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
