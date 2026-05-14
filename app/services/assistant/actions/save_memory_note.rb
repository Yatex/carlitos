module Assistant
  module Actions
    class SaveMemoryNote
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        note = @user.memory_notes.create!(
          title: @arguments["title"].presence || I18n.t("assistant.actions.save_memory_note.default_title"),
          content: @arguments["content"],
          source: @arguments["source"].presence || "assistant"
        )
        ActionResult.new(success: true, message: I18n.t("assistant.actions.save_memory_note.success"), record: note)
      end
    end
  end
end
