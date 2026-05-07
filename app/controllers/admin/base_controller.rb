module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    private

    def require_admin!
      return if current_user.admin_like?

      redirect_to dashboard_path, alert: "No tenés permisos para entrar al panel admin."
    end

    def require_super_admin!
      return if current_user.super_admin?

      redirect_to admin_users_path, alert: "Esta acción es solo para super admins."
    end
  end
end
