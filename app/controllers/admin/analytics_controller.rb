module Admin
  class AnalyticsController < Admin::BaseController
    def index
      @stats = Admin::PlatformStats.new.call
      @plans = Billing::PlanCatalog.all
    end
  end
end
