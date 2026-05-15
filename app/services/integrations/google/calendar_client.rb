module Integrations
  module Google
    class CalendarClient
      API_BASE = "https://www.googleapis.com/calendar/v3".freeze

      def initialize(user:, api_client: Integrations::GoogleApiClient.new(user: user, provider: "google_calendar"))
        @user = user
        @api_client = api_client
      end

      def create_event(title:, starts_at:, ends_at: nil, description: nil)
        start_time = parse_time(starts_at)
        end_time = ends_at.present? ? parse_time(ends_at) : start_time + 1.hour
        payload = {
          summary: title,
          description: description,
          start: { dateTime: start_time.iso8601, timeZone: @user.timezone },
          end: { dateTime: end_time.iso8601, timeZone: @user.timezone }
        }.compact

        @api_client.post_json("#{API_BASE}/calendars/primary/events", payload)
      end

      private

      def parse_time(value)
        return value if value.respond_to?(:iso8601)

        Time.zone.parse(value.to_s) || raise(ArgumentError, "Invalid calendar time")
      end
    end
  end
end
