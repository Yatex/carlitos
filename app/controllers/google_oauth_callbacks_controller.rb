class GoogleOauthCallbacksController < ApplicationController
  before_action :authenticate_user!

  def show
    state = Integrations::GoogleOauthService.decode_state(params[:state])&.with_indifferent_access
    return redirect_to(settings_path, alert: "No pudimos validar la conexión con Google.") unless valid_state?(state)

    service = Integrations::GoogleOauthService.new(user: current_user, provider: state["provider"])
    result = service.exchange_code(params[:code], callback_url: google_oauth_callback_url)

    if result[:ok]
      connect_provider(state["provider"], result[:body])
      redirect_to settings_path, notice: "#{Integrations::Catalog.fetch(state['provider'])[:name]} conectado."
    else
      mark_provider_error(state["provider"], result[:error])
      redirect_to settings_path, alert: "Google no pudo completar la conexión: #{result[:error]}"
    end
  end

  private

  def valid_state?(state)
    state.present? &&
      state[:user_id].to_i == current_user.id &&
      state[:provider].in?(%w[gmail google_calendar]) &&
      Time.zone.at(state[:issued_at].to_i) > 15.minutes.ago
  end

  def connect_provider(provider, token_response)
    connection = current_user.integration_connections.find_or_initialize_by(provider: provider)
    connection.update!(
      status: "connected",
      display_name: current_user.email,
      connected_at: Time.current,
      metadata: Integrations::GoogleOauthService.metadata_from_token_response(provider, token_response)
    )
  end

  def mark_provider_error(provider, error)
    connection = current_user.integration_connections.find_or_initialize_by(provider: provider)
    connection.update!(
      status: "error",
      metadata: connection.metadata.merge("last_error" => error, "errored_at" => Time.current.iso8601)
    )
  end
end
