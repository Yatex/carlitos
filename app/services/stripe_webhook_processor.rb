class StripeWebhookProcessor
  def initialize(event)
    @event = event
  end

  def process
    case @event["type"]
    when "checkout.session.completed"
      process_checkout_completed(@event.dig("data", "object"))
    when "customer.subscription.created", "customer.subscription.updated"
      process_subscription_updated(@event.dig("data", "object"))
    when "customer.subscription.deleted"
      process_subscription_deleted(@event.dig("data", "object"))
    else
      Rails.logger.info("[Stripe] Ignored webhook #{@event['type']}")
    end
  end

  private

  def process_checkout_completed(session)
    user = User.find_by(id: session["client_reference_id"]) || User.find_by(stripe_customer_id: session["customer"])
    return unless user

    user.update!(
      stripe_customer_id: session["customer"],
      stripe_subscription_id: session["subscription"],
      subscription_status: "active",
      current_plan: normalize_plan(session.dig("metadata", "plan").presence || "pro")
    )
  end

  def process_subscription_updated(subscription)
    user = User.find_by(stripe_subscription_id: subscription["id"]) || User.find_by(stripe_customer_id: subscription["customer"])
    return unless user

    user.update!(
      stripe_customer_id: subscription["customer"],
      stripe_subscription_id: subscription["id"],
      subscription_status: subscription["status"],
      current_plan: normalize_plan(subscription.dig("metadata", "plan").presence || user.current_plan)
    )
  end

  def process_subscription_deleted(subscription)
    user = User.find_by(stripe_subscription_id: subscription["id"]) || User.find_by(stripe_customer_id: subscription["customer"])
    return unless user

    user.update!(
      stripe_subscription_id: nil,
      subscription_status: "canceled",
      current_plan: "free"
    )
  end

  def normalize_plan(plan_key)
    Billing::PlanCatalog.find(plan_key)&.key || "free"
  end
end
