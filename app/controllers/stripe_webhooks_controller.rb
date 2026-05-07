class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.raw_post
    event = StripeClient.new.parse_webhook_event(payload, request.headers["Stripe-Signature"])

    return head :bad_request unless event

    StripeWebhookProcessor.new(event).process
    head :ok
  end
end
