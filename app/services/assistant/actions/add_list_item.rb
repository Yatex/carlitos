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
        ActionResult.new(success: true, message: "Agregué #{item.content} a #{list.title}.", record: item)
      end

      private

      def find_or_create_list
        title = @arguments["list_title"].presence || "General"
        @user.memory_lists.where("lower(title) = ?", title.downcase).first_or_create!(title:)
      end
    end
  end
end
