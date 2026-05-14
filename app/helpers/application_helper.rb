module ApplicationHelper
  def page_title
    content_for?(:title) ? content_for(:title) : t("meta.title")
  end

  def page_description
    content_for?(:description) ? content_for(:description) : t("meta.description")
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

  def language_switch_path(locale)
    url_for(params: request.query_parameters.merge(locale: locale), only_path: true)
  end

  def localized_status(status)
    t("statuses.subscription.#{status}", default: status.to_s.humanize)
  end

  def localized_integration_status(status)
    t("statuses.integration.#{status}", default: status.to_s.humanize)
  end

  def localized_role(role)
    t("statuses.role.#{role}", default: role.to_s.humanize)
  end

  def localized_assistant_channel(channel)
    t("statuses.assistant_channel.#{channel}", default: channel.to_s.humanize)
  end

  def localized_assistant_direction(direction)
    t("statuses.assistant_direction.#{direction}", default: direction.to_s.humanize)
  end
end
