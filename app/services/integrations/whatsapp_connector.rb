module Integrations
  class WhatsappConnector
    def initialize(user:, phone:, client: TwilioClient.new)
      @user = user
      @phone = normalize_phone(phone)
      @client = client
    end

    def call
      return { ok: false, message: "Ingresá un número de WhatsApp." } if @phone.blank?

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
          body: "Hola, soy Carlitos. Ya podés responder este mensaje para vincular WhatsApp con tu memoria."
        )
        { ok: true, message: "Te mandamos un WhatsApp para terminar la conexión." }
      else
        Rails.logger.warn("[WhatsApp] Twilio credentials missing; connection saved as pending for #{@phone}.")
        { ok: true, message: "Guardamos tu número. Cuando Twilio esté configurado, Carlitos podrá completar la conexión." }
      end
    end

    private

    def normalize_phone(phone)
      phone.to_s.strip.delete_prefix("whatsapp:")
    end
  end
end
