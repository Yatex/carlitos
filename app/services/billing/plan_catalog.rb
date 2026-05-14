module Billing
  Plan = Data.define(
    :key,
    :name,
    :price,
    :description,
    :badge,
    :features,
    :limits,
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
  end

  class PlanCatalog
    PLANS = [
      Plan.new(
        key: "free",
        name: "Free trial",
        price: "14 días",
        description: "Se activa automáticamente al crear tu cuenta para probar Carlitos sin fricción.",
        badge: "Inicio automático",
        features: [
          "Recordatorios básicos",
          "Listas personales",
          "Mensajes mensuales limitados",
          "Acceso por WhatsApp",
          "Captura manual desde la web"
        ],
        limits: [
          "Disponible solo durante los primeros 14 días",
          "Sin notas de voz",
          "Sin búsqueda avanzada",
          "Sin integraciones de calendario"
        ],
        stripe_price_env: nil,
        recommended: false,
        coming_soon: false
      ),
      Plan.new(
        key: "pro",
        name: "Pro",
        price: "USD 9/mes",
        description: "Para usar a Carlitos todos los días como memoria externa personal.",
        badge: "Recomendado",
        features: [
          "Recordatorios ilimitados",
          "Listas ilimitadas",
          "Briefing diario",
          "Notas de voz",
          "Búsqueda en tu memoria",
          "Integración con calendario",
          "Contexto desde Gmail",
          "Procesamiento prioritario"
        ],
        limits: [],
        stripe_price_env: "STRIPE_PRICE_PRO",
        recommended: true,
        coming_soon: false
      ),
      Plan.new(
        key: "family",
        name: "Family / Team",
        price: "A definir",
        description: "Para coordinar familia, socios o equipos chicos con memoria compartida.",
        badge: "Próximamente",
        features: [
          "Listas compartidas",
          "Recordatorios compartidos",
          "Múltiples miembros",
          "Controles de administrador",
          "Contexto compartido por grupo",
          "Briefings para cada miembro"
        ],
        limits: [
          "Checkout se activa al configurar STRIPE_PRICE_FAMILY"
        ],
        stripe_price_env: "STRIPE_PRICE_FAMILY",
        recommended: false,
        coming_soon: true
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
