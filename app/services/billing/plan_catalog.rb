module Billing
  Plan = Data.define(
    :key,
    :stripe_price_env,
    :recommended,
    :coming_soon
  ) do
    def paid?
      key != "free"
    end

    def stripe_price_id
      stripe_price_env.present? ? ENV[stripe_price_env] : nil
    end

    def checkoutable?
      paid? && !coming_soon
    end

    def configured_for_checkout?
      checkoutable? && stripe_price_id.present?
    end

    def name
      translate(:name)
    end

    def price
      translate(:price)
    end

    def description
      translate(:description)
    end

    def badge
      translate(:badge)
    end

    def features
      translate(:features)
    end

    def limits
      translate(:limits)
    end

    private

    def translate(attribute)
      I18n.t("billing.plans.#{key}.#{attribute}")
    end
  end

  class PlanCatalog
    PLANS = [
      Plan.new(
        key: "free",
        stripe_price_env: nil,
        recommended: false,
        coming_soon: false
      ),
      Plan.new(
        key: "pro",
        stripe_price_env: "STRIPE_PRICE_PRO",
        recommended: true,
        coming_soon: false
      ),
      Plan.new(
        key: "family",
        stripe_price_env: "STRIPE_PRICE_FAMILY",
        recommended: false,
        coming_soon: false
      )
    ].freeze

    class << self
      def all
        PLANS
      end

      def paid
        all.select(&:paid?)
      end

      def find(key)
        all.find { |plan| plan.key == key.to_s }
      end

      def find!(key)
        find(key) || raise(ArgumentError, "Unknown billing plan: #{key}")
      end

      def current_for(user)
        find(user.current_plan) || find!("free")
      end
    end
  end
end
