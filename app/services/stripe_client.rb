require "net/http"
require "json"
require "openssl"

class StripeClient
  API_BASE = "https://api.stripe.com/v1".freeze
  API_VERSION = "2026-02-25.clover".freeze

  def initialize(secret_key: ENV["STRIPE_SECRET_KEY"], webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"])
    @secret_key = secret_key
    @webhook_secret = webhook_secret
  end

  def configured?
    @secret_key.present?
  end

  def create_checkout_session(user:, plan:, success_url:, cancel_url:)
    return missing_configuration("STRIPE_SECRET_KEY") unless configured?

    billing_plan = Billing::PlanCatalog.find(plan)
    return { error: I18n.t("stripe.errors.unknown_plan") } unless billing_plan
    return { error: I18n.t("stripe.errors.no_checkout", plan: billing_plan.name) } unless billing_plan.checkoutable?

    price_id = billing_plan.stripe_price_id
    return { error: I18n.t("stripe.errors.missing_price", plan: billing_plan.name, env: billing_plan.stripe_price_env) } if price_id.blank?

    customer = ensure_customer(user)
    return customer if customer[:error]

    post_form(
      "/checkout/sessions",
      {
        mode: "subscription",
        customer: customer[:id],
        client_reference_id: user.id,
        success_url: success_url,
        cancel_url: cancel_url,
        "metadata[plan]" => billing_plan.key,
        "subscription_data[metadata][plan]" => billing_plan.key,
        "line_items[0][price]" => price_id,
        "line_items[0][quantity]" => 1
      }
    )
  end

  def create_customer_portal_session(user:, return_url:)
    return missing_configuration("STRIPE_SECRET_KEY") unless configured?
    return { error: I18n.t("stripe.errors.missing_customer") } if user.stripe_customer_id.blank?

    post_form("/billing_portal/sessions", { customer: user.stripe_customer_id, return_url: })
  end

  def parse_webhook_event(payload, signature_header)
    if @webhook_secret.present?
      return nil unless valid_signature?(payload, signature_header)
    else
      Rails.logger.warn("[Stripe] STRIPE_WEBHOOK_SECRET missing; parsing webhook without signature verification.")
    end

    JSON.parse(payload)
  rescue JSON::ParserError => e
    Rails.logger.warn("[Stripe] Invalid webhook payload: #{e.message}")
    nil
  end

  private

  def ensure_customer(user)
    return { id: user.stripe_customer_id } if user.stripe_customer_id.present?

    response = post_form("/customers", { email: user.email, name: user.name, "metadata[user_id]" => user.id })
    user.update!(stripe_customer_id: response[:id]) if response[:id].present?
    response
  end

  def post_form(path, form_data)
    uri = URI("#{API_BASE}#{path}")
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@secret_key, "")
    request["Stripe-Version"] = API_VERSION
    request.set_form_data(form_data.compact)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    body = JSON.parse(response.body.presence || "{}")

    if response.is_a?(Net::HTTPSuccess)
      body.symbolize_keys
    else
      { error: body.dig("error", "message") || I18n.t("stripe.errors.response", code: response.code) }
    end
  rescue StandardError => e
    Rails.logger.warn("[Stripe] API request failed: #{e.class} #{e.message}")
    { error: e.message }
  end

  def missing_configuration(name)
    Rails.logger.warn("[Stripe] #{name} missing; Stripe action skipped.")
    { error: I18n.t("stripe.errors.not_configured") }
  end

  def valid_signature?(payload, header)
    timestamp = header.to_s.split(",").find { |part| part.start_with?("t=") }&.split("=", 2)&.last
    signature = header.to_s.split(",").find { |part| part.start_with?("v1=") }&.split("=", 2)&.last
    return false if timestamp.blank? || signature.blank?

    expected = OpenSSL::HMAC.hexdigest("SHA256", @webhook_secret, "#{timestamp}.#{payload}")
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end
end
