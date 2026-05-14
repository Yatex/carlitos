module Assistant
  class ActionDispatcher
    ACTIONS = {
      "create_reminder" => "Assistant::Actions::CreateReminder",
      "create_list" => "Assistant::Actions::CreateList",
      "add_list_item" => "Assistant::Actions::AddListItem",
      "save_memory_note" => "Assistant::Actions::SaveMemoryNote",
      "schedule_daily_briefing" => "Assistant::Actions::ScheduleDailyBriefing",
      "search_memory" => "Assistant::Actions::SearchMemory"
    }.freeze

    def initialize(user:, decision:)
      @user = user
      @decision = decision
    end

    def call
      klass_name = ACTIONS[@decision.action]
      return ActionResult.new(success: false, message: I18n.t("assistant.unsupported_action")) unless klass_name

      klass_name.constantize.new(user: @user, arguments: @decision.arguments || {}).call
    end
  end
end
