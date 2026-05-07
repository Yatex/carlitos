module ApplicationHelper
  DEFAULT_TITLE = "Carlitos — Tu asistente de memoria por WhatsApp".freeze
  DEFAULT_DESCRIPTION = "Carlitos te ayuda a guardar recordatorios, tareas, listas e ideas desde WhatsApp para liberar tu cabeza y mantener todo bajo control.".freeze

  def page_title
    content_for?(:title) ? content_for(:title) : DEFAULT_TITLE
  end

  def page_description
    content_for?(:description) ? content_for(:description) : DEFAULT_DESCRIPTION
  end

  def nav_link_to(label, path, options = {})
    class_name = options.delete(:class) || "font-semibold text-muted transition hover:text-ink"
    link_to label, path, class: class_name, **options
  end

  def iana_time_zone_options(selected = nil)
    zones = ActiveSupport::TimeZone.all.map do |zone|
      label = "#{zone.formatted_offset} #{zone.name}"
      [label, zone.tzinfo.identifier]
    end

    options_for_select(zones, selected.presence || "America/Montevideo")
  end
end
