module Integrations
  class WhatsappConnector
    def initialize(user:, phone:, client: TwilioClient.new)
      @user = user
      @phone = normalize_phone(phone)
      @client = client
    end

    def call
      return { ok: false, message: I18n.t("whatsapp.connector.missing_phone") } if @phone.blank?

      connection = @user.integration_connections.find_or_initialize_by(provider: "whatsapp")
      connection.assign_attributes(
        status: "pending",
        display_name: @phone,
        metadata: connection.metadata.merge(
          "phone" => @phone,
          "setup_channel" => "settings",
          "twilio_configured" => @client.configured?,
          "pending_reason" => "waiting_for_first_inbound_message"
        )
      )
      connection.save!

      if @client.configured?
        WhatsappOutboundMessageService.new(client: @client).deliver(
          user: @user,
          to: @phone,
          body: I18n.t("whatsapp.connector.setup_message")
        )
        { ok: true, message: I18n.t("whatsapp.connector.sent") }
      else
        Rails.logger.warn("[WhatsApp] Twilio credentials missing; connection saved as pending for #{@phone}.")
        { ok: true, message: I18n.t("whatsapp.connector.saved_pending") }
      end
    end

    private

    def normalize_phone(phone)
      phone.to_s.strip.delete_prefix("whatsapp:")
    end
  end
end
