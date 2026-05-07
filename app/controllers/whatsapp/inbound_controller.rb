module Whatsapp
  class InboundController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      return head :unauthorized unless webhook_authorized?

      result = WhatsappInboundProcessor.new(params.to_unsafe_h).process
      render plain: result[:response], content_type: "text/plain"
    end

    private

    def webhook_authorized?
      expected = ENV["TWILIO_WEBHOOK_AUTH_TOKEN"].presence
      return true unless expected

      ActiveSupport::SecurityUtils.secure_compare(expected, request.headers["X-Carlitos-Webhook-Token"].to_s)
    end
  end
end
