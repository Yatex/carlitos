require "net/http"
require "json"

module Assistant
  class DecisionService
    def initialize(provider: ENV["AI_PROVIDER"], service_url: ENV["CARLITOS_AI_SERVICE_URL"])
      @provider = provider
      @service_url = service_url
    end

    def call(user:, input:, channel: "web")
      if external_service_configured?
        external_decision(user:, input:, channel:)
      else
        local_fallback(user:, input:)
      end
    rescue StandardError => e
      Rails.logger.warn("[Assistant] Decision service failed; using fallback: #{e.class} #{e.message}")
      local_fallback(user:, input:)
    end

    private

    def external_service_configured?
      @provider.present? && @service_url.present?
    end

    def external_decision(user:, input:, channel:)
      uri = URI(@service_url)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{ENV['CARLITOS_AI_SERVICE_TOKEN']}" if ENV["CARLITOS_AI_SERVICE_TOKEN"].present?
      request.body = {
        prompt: PromptBuilder.new(user:, input:, channel:).call,
        input: input,
        user: { id: user.id, timezone: user.timezone },
        channel: channel
      }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
      raise "External service returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      parsed = JSON.parse(response.body)
      Decision.new(
        action: parsed.fetch("action", "unknown"),
        arguments: parsed.fetch("arguments", {}),
        confidence: parsed.fetch("confidence", 0.5),
        raw_input: input
      )
    end

    def local_fallback(user:, input:)
      normalized = input.to_s.strip

      if (match = normalized.match(/\Arecord[aá]me\s+(.+?)(?:\s+(hoy|mañana|pasado mañana|lunes|martes|miércoles|miercoles|jueves|viernes|sábado|sabado|domingo))?(?:\s+a\s+las\s+(\d{1,2})(?::(\d{2}))?)?\z/i))
        title = match[1].strip
        return Decision.new(
          action: "create_reminder",
          arguments: {
            "title" => title,
            "body" => normalized,
            "remind_at" => parse_spanish_time(user, match[2], match[3], match[4])&.iso8601
          }.compact,
          confidence: 0.8,
          raw_input: input
        )
      end

      if (match = normalized.match(/agreg[aá]\s+(.+?)\s+a\s+la\s+lista\s+del?\s+(.+)/i))
        return Decision.new(
          action: "add_list_item",
          arguments: { "content" => match[1].strip, "list_title" => match[2].strip },
          confidence: 0.85,
          raw_input: input
        )
      end

      if (match = normalized.match(/guard[aá]\s+(?:que\s+)?(.+)/i))
        content = match[1].strip
        return Decision.new(
          action: "save_memory_note",
          arguments: { "title" => content.truncate(64), "content" => content, "source" => "assistant" },
          confidence: 0.78,
          raw_input: input
        )
      end

      if normalized.match?(/briefing|resumen/i)
        return Decision.new(
          action: "schedule_daily_briefing",
          arguments: { "enabled" => true, "delivery_time" => "08:00" },
          confidence: 0.7,
          raw_input: input
        )
      end

      Decision.new(
        action: "save_memory_note",
        arguments: { "title" => "Mensaje guardado", "content" => normalized, "source" => "assistant" },
        confidence: 0.4,
        raw_input: input
      )
    end

    def parse_spanish_time(user, day_text, hour_text, minute_text)
      zone = ActiveSupport::TimeZone[user.timezone] || Time.zone
      date = Date.current
      day = day_text.to_s.downcase

      date += 1.day if day == "mañana"
      date += 2.days if day == "pasado mañana"
      date = next_weekday(date, day) if weekdays.key?(day)

      hour = hour_text.presence&.to_i || 9
      minute = minute_text.presence&.to_i || 0
      zone.local(date.year, date.month, date.day, hour, minute)
    end

    def weekdays
      {
        "lunes" => 1,
        "martes" => 2,
        "miércoles" => 3,
        "miercoles" => 3,
        "jueves" => 4,
        "viernes" => 5,
        "sábado" => 6,
        "sabado" => 6,
        "domingo" => 0
      }
    end

    def next_weekday(date, day)
      target = weekdays[day]
      days_ahead = (target - date.wday) % 7
      days_ahead = 7 if days_ahead.zero?
      date + days_ahead.days
    end
  end
end
