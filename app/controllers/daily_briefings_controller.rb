class DailyBriefingsController < ApplicationController
  before_action :authenticate_user!

  def edit
    @daily_briefing = current_user.daily_briefing || current_user.create_daily_briefing!(timezone: current_user.timezone)
  end

  def update
    @daily_briefing = current_user.daily_briefing || current_user.create_daily_briefing!(timezone: current_user.timezone)

    if @daily_briefing.update(daily_briefing_params)
      redirect_back fallback_location: edit_daily_briefing_path, notice: "Briefing diario actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def daily_briefing_params
    params.require(:daily_briefing).permit(:enabled, :delivery_time, :timezone)
  end
end
