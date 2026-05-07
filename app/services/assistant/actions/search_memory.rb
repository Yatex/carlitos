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
                    "Encontré esto: #{notes.map(&:title).to_sentence}."
                  else
                    "No encontré nada con esa búsqueda todavía."
                  end

        ActionResult.new(success: true, message:, record: notes)
      end
    end
  end
end
