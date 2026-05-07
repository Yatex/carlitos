module Assistant
  module Actions
    class SaveMemoryNote
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        note = @user.memory_notes.create!(
          title: @arguments["title"].presence || "Nota guardada",
          content: @arguments["content"],
          source: @arguments["source"].presence || "assistant"
        )
        ActionResult.new(success: true, message: "Lo guardé en tu memoria.", record: note)
      end
    end
  end
end
