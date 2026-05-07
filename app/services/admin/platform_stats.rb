module Admin
  class PlatformStats
    ACTIVE_PAID_STATUSES = %w[active trialing].freeze

    def call
      {
        total_users: User.count,
        admin_users: User.where(role: %i[admin super_admin]).count,
        paying_users: paying_users.count,
        free_users: User.where(current_plan: "free").count,
        early_access_signups: EarlyAccessSignup.count,
        enabled_daily_briefings: DailyBriefing.where(enabled: true).count,
        reminders: Reminder.count,
        memory_lists: MemoryList.count,
        memory_notes: MemoryNote.count,
        assistant_messages: AssistantMessage.count,
        assistant_runs: AssistantRun.count,
        whatsapp_connections: IntegrationConnection.where(provider: "whatsapp", status: "connected").count,
        gmail_connections: IntegrationConnection.where(provider: "gmail", status: "connected").count,
        calendar_connections: IntegrationConnection.where(provider: "google_calendar", status: "connected").count,
        users_by_plan: User.group(:current_plan).count,
        users_by_subscription_status: User.group(:subscription_status).count,
        users_by_role: User.group(:role).count,
        recent_users: User.order(created_at: :desc).limit(8)
      }
    end

    private

    def paying_users
      User.where(current_plan: %w[pro family], subscription_status: ACTIVE_PAID_STATUSES)
          .where("plan_expires_at IS NULL OR plan_expires_at > ?", Time.current)
    end
  end
end
