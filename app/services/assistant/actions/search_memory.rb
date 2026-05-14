module Assistant
  module Actions
    class SearchMemory
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        query = @arguments["query"].to_s
        notes = @user.memory_notes.where("title ILIKE :q OR content ILIKE :q", q: "%#{query}%").limit(5)
        message = if notes.any?
                    I18n.t("assistant.actions.search_memory.found", titles: notes.map(&:title).to_sentence)
                  else
                    I18n.t("assistant.actions.search_memory.not_found")
                  end

        ActionResult.new(success: true, message:, record: notes)
      end
    end
  end
end
