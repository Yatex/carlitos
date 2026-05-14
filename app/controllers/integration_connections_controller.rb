class IntegrationConnectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_provider!

  def create
    if google_provider?
      connect_google_provider
    else
      connect_whatsapp
    end
  end

  def destroy
    connection = current_user.integration_connections.find_or_initialize_by(provider: params[:provider])
    connection.update!(
      status: "disconnected",
      display_name: nil,
      external_id: nil,
      connected_at: nil,
      last_synced_at: nil,
      metadata: {}
    )

    redirect_to settings_path, notice: t("flash.integrations.disconnected", name: Integrations::Catalog.fetch(params[:provider])[:name])
  end

  private

  def validate_provider!
    return if Integrations::Catalog.providers.include?(params[:provider])

    redirect_to settings_path, alert: t("flash.integrations.unknown")
  end

  def google_provider?
    params[:provider].in?(%w[gmail google_calendar])
  end

  def connect_google_provider
    service = Integrations::GoogleOauthService.new(user: current_user, provider: params[:provider])

    unless service.configured?
      connection = current_user.integration_connections.find_or_initialize_by(provider: params[:provider])
      connection.update!(
        status: "pending",
        metadata: {
          "missing_env" => %w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET],
          "requested_scopes" => service.scopes
        }
      )
      redirect_to settings_path, alert: t("flash.integrations.google_missing_config", name: Integrations::Catalog.fetch(params[:provider])[:name])
      return
    end

    redirect_to service.authorization_url(callback_url: google_oauth_callback_url), allow_other_host: true
  end

  def connect_whatsapp
    result = Integrations::WhatsappConnector.new(user: current_user, phone: params[:phone]).call
    flash_type = result[:ok] ? :notice : :alert
    redirect_to settings_path, flash: { flash_type => result[:message] }
  end
end
