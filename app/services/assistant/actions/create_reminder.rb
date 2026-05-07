module Assistant
  module Actions
    class CreateReminder
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        reminder = @user.reminders.create!(
          title: @arguments["title"],
          body: @arguments["body"],
          remind_at: parse_time(@arguments["remind_at"]),
          recurrence_rule: @arguments["recurrence_rule"],
          status: "pending"
        )
        ActionResult.new(success: true, message: "Listo. Te lo recuerdo#{time_fragment(reminder)}.", record: reminder)
      end

      private

      def parse_time(value)
        Time.zone.parse(value) if value.present?
      end

      def time_fragment(reminder)
        reminder.remind_at ? " el #{I18n.l(reminder.remind_at, format: :short)}" : ""
      end
    end
  end
end
