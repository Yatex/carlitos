module Assistant
  module Actions
    class ScheduleDailyBriefing
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        briefing = @user.daily_briefing || @user.create_daily_briefing!(timezone: @user.timezone)
        briefing.update!(
          enabled: ActiveModel::Type::Boolean.new.cast(@arguments.fetch("enabled", true)),
          delivery_time: @arguments["delivery_time"].presence || briefing.delivery_time,
          timezone: @arguments["timezone"].presence || @user.timezone
        )
        ActionResult.new(success: true, message: I18n.t("assistant.actions.schedule_daily_briefing.success"), record: briefing)
      end
    end
  end
end
