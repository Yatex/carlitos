class RemindersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reminder, only: [:update]

  def index
    @reminders = current_user.reminders.upcoming
  end

  def new
    @reminder = current_user.reminders.new
  end

  def create
    @reminder = current_user.reminders.new(reminder_params)

    if @reminder.save
      redirect_back fallback_location: dashboard_path, notice: t("flash.reminders.created")
    else
      redirect_back fallback_location: dashboard_path, alert: @reminder.errors.full_messages.to_sentence
    end
  end

  def update
    if @reminder.update(reminder_params)
      redirect_back fallback_location: reminders_path, notice: t("flash.reminders.updated")
    else
      redirect_back fallback_location: reminders_path, alert: @reminder.errors.full_messages.to_sentence
    end
  end

  private

  def set_reminder
    @reminder = current_user.reminders.find(params[:id])
  end

  def reminder_params
    params.require(:reminder).permit(:title, :body, :remind_at, :recurrence_rule, :status)
  end
end
