module Whatsapp
  class InboundController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      return head :unauthorized unless webhook_authorized?

      result = WhatsappInboundProcessor.new(params.to_unsafe_h).process
      render xml: twiml_message(result[:response])
    end

    private

    def webhook_authorized?
      expected = ENV["TWILIO_WEBHOOK_AUTH_TOKEN"].presence
      return true unless expected

      provided = request.headers["X-Carlitos-Webhook-Token"].presence || params[:webhook_token].to_s
      provided.present? &&
        provided.bytesize == expected.bytesize &&
        ActiveSupport::SecurityUtils.secure_compare(expected, provided)
    end

    def twiml_message(body)
      "<Response><Message>#{ERB::Util.html_escape(body)}</Message></Response>"
    end
  end
end
