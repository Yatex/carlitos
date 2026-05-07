class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @reminder = current_user.reminders.new
    @memory_list = current_user.memory_lists.new
    @memory_note = current_user.memory_notes.new(source: "web")
    @daily_briefing = current_user.daily_briefing || current_user.create_daily_briefing!(timezone: current_user.timezone)
    @recent_reminders = current_user.reminders.upcoming.limit(5)
    @recent_lists = current_user.memory_lists.recent.includes(:memory_list_items).limit(5)
    @recent_notes = current_user.memory_notes.recent.limit(5)
    @recent_activity = current_user.assistant_messages.recent.limit(5)
  end
end
