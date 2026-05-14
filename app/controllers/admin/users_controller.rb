module Admin
  class UsersController < Admin::BaseController
    PER_PAGE = 25

    before_action :set_user, only: %i[extend_plan update_role]
    before_action :require_super_admin!, only: :update_role

    def index
      scope = User.order(created_at: :desc)
      scope = scope.where("email ILIKE ?", "%#{User.sanitize_sql_like(params[:email])}%") if params[:email].present?
      scope = scope.where(role: params[:role]) if User.roles.key?(params[:role].to_s)
      scope = scope.where(current_plan: params[:plan]) if User::PLANS.include?(params[:plan].to_s)
      scope = scope.where(subscription_status: params[:status]) if User::SUBSCRIPTION_STATUSES.include?(params[:status].to_s)

      @page = [params[:page].to_i, 1].max
      @total_count = scope.count
      @total_pages = (@total_count.to_f / PER_PAGE).ceil
      @users = scope.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
      @plans = Billing::PlanCatalog.all
      @grantable_plans = Billing::PlanCatalog.paid
    end

    def extend_plan
      if (message = extend_plan_blocker)
        redirect_to admin_users_path, alert: message
        return
      end

      plan = Billing::PlanCatalog.find(params[:current_plan])
      unless plan
        redirect_to admin_users_path, alert: t("flash.admin.invalid_plan")
        return
      end
      unless plan.paid?
        redirect_to admin_users_path, alert: t("flash.admin.free_plan_no_extend")
        return
      end

      expires_at = parse_end_date(params[:plan_expires_on])
      if expires_at.blank?
        redirect_to admin_users_path, alert: t("flash.admin.future_date")
        return
      end

      @user.update!(
        current_plan: plan.key,
        subscription_status: "active",
        plan_expires_at: expires_at,
        plan_granted_by: current_user,
        plan_granted_at: Time.current
      )

      redirect_to admin_users_path, notice: t("flash.admin.plan_updated", email: @user.email)
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_users_path, alert: e.record.errors.full_messages.to_sentence
    end

    def update_role
      new_role = params[:role].to_s
      unless User.roles.key?(new_role)
        redirect_to admin_users_path, alert: t("flash.admin.invalid_role")
        return
      end

      if @user == current_user
        redirect_to admin_users_path, alert: t("flash.admin.own_role")
        return
      end

      if @user.super_admin?
        redirect_to admin_users_path, alert: t("flash.admin.other_super_admin")
        return
      end

      @user.update!(role: new_role)
      redirect_to admin_users_path, notice: t("flash.admin.role_updated", email: @user.email)
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_users_path, alert: e.record.errors.full_messages.to_sentence
    end

    private

    def set_user
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_users_path, alert: t("flash.admin.user_not_found")
    end

    def extend_plan_blocker
      return nil if current_user.super_admin?
      return t("flash.admin.super_admin_plan_blocked") if @user.super_admin?

      nil
    end

    def parse_end_date(value)
      return nil if value.blank?

      date = Date.parse(value.to_s)
      return nil if date < Date.current

      date.end_of_day
    rescue ArgumentError
      nil
    end

  end
end
