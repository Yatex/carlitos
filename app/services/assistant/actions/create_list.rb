module Assistant
  module Actions
    class CreateList
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        list = @user.memory_lists.create!(title: @arguments["title"])
        ActionResult.new(success: true, message: "Creé la lista #{list.title}.", record: list)
      end
    end
  end
end
