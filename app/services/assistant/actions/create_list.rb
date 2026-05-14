module Assistant
  module Actions
    class CreateList
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        list = @user.memory_lists.create!(title: @arguments["title"])
        ActionResult.new(success: true, message: I18n.t("assistant.actions.create_list.success", title: list.title), record: list)
      end
    end
  end
end
