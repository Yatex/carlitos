module Assistant
  module Actions
    class AddListItem
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        list = find_or_create_list
        item = list.memory_list_items.create!(content: @arguments["content"])
        ActionResult.new(success: true, message: I18n.t("assistant.actions.add_list_item.success", item: item.content, list: list.title), record: item)
      end

      private

      def find_or_create_list
        title = @arguments["list_title"].presence || I18n.t("assistant.default_list")
        @user.memory_lists.where("lower(title) = ?", title.downcase).first_or_create!(title:)
      end
    end
  end
end
