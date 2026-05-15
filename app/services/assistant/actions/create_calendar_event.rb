module Assistant
  module Actions
    class CreateCalendarEvent
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        title = @arguments["title"].presence || @arguments["summary"].presence
        starts_at = @arguments["starts_at"].presence || @arguments["start_at"].presence || @arguments["start"].presence

        unless title.present? && starts_at.present?
          return ActionResult.new(success: false, message: I18n.t("assistant.actions.create_calendar_event.missing_fields"))
        end

        event = Time.use_zone(@user.timezone) do
          Integrations::Google::CalendarClient.new(user: @user).create_event(
            title: title,
            starts_at: starts_at,
            ends_at: @arguments["ends_at"].presence || @arguments["end_at"].presence,
            description: @arguments["description"]
          )
        end

        ActionResult.new(
          success: true,
          message: I18n.t("assistant.actions.create_calendar_event.created", title: title),
          record: event
        )
      rescue Integrations::GoogleApiClient::MissingConnection, Integrations::GoogleApiClient::MissingToken
        ActionResult.new(success: false, message: I18n.t("assistant.actions.create_calendar_event.connect_calendar"))
      rescue Integrations::GoogleApiClient::Error => e
        ActionResult.new(success: false, message: I18n.t("assistant.actions.create_calendar_event.failed", error: e.message))
      rescue ArgumentError
        ActionResult.new(success: false, message: I18n.t("assistant.actions.create_calendar_event.missing_fields"))
      end
    end
  end
end
