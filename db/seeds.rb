# Seed data for a useful local Carlitos dashboard.

demo_user = User.find_or_initialize_by(email: "demo@carlitos.test")
demo_user.assign_attributes(
  name: "Demo Carlitos",
  timezone: "America/Montevideo",
  role: "user",
  subscription_status: "active",
  current_plan: "pro",
  plan_expires_at: 2.months.from_now.end_of_day,
  password: "password123",
  password_confirmation: "password123"
)
demo_user.save!

admin_user = User.find_or_initialize_by(email: "admin@carlitos.test")
admin_user.assign_attributes(
  name: "Admin Carlitos",
  timezone: "America/Montevideo",
  role: "super_admin",
  subscription_status: "active",
  current_plan: "pro",
  password: "password123",
  password_confirmation: "password123"
)
admin_user.save!

demo_user.daily_briefing.update!(
  enabled: true,
  delivery_time: "08:30",
  timezone: demo_user.timezone
)

[
  {
    provider: "gmail",
    status: "pending",
    display_name: "demo@carlitos.test",
    metadata: {
      seeded: true,
      requested_scopes: Integrations::Catalog.fetch("gmail")[:scopes],
      pending_reason: "configure_google_oauth"
    }
  },
  {
    provider: "google_calendar",
    status: "pending",
    display_name: "demo@carlitos.test",
    metadata: {
      seeded: true,
      requested_scopes: Integrations::Catalog.fetch("google_calendar")[:scopes],
      pending_reason: "configure_google_oauth"
    }
  },
  {
    provider: "whatsapp",
    status: "connected",
    display_name: "+59899999999",
    connected_at: Time.current,
    metadata: {
      seeded: true,
      phone: "+59899999999"
    }
  }
].each do |attributes|
  connection = demo_user.integration_connections.find_or_initialize_by(provider: attributes[:provider])
  connection.assign_attributes(attributes)
  connection.save!
end

[
  {
    title: "Pagar el alquiler",
    body: "Transferir antes de las 10 y guardar el comprobante.",
    remind_at: 2.days.from_now.change(hour: 10, min: 0),
    status: "pending"
  },
  {
    title: "Responder follow-up con Ana",
    body: "Mandar resumen de próximos pasos del proyecto.",
    remind_at: 1.day.from_now.change(hour: 15, min: 30),
    status: "pending"
  },
  {
    title: "Comprar regalo de cumpleaños",
    body: "Buscar algo simple para el sábado.",
    remind_at: 4.days.from_now.change(hour: 18, min: 0),
    status: "pending"
  }
].each do |attributes|
  demo_user.reminders.find_or_create_by!(title: attributes[:title]) do |reminder|
    reminder.assign_attributes(attributes)
  end
end

super_list = demo_user.memory_lists.find_or_create_by!(title: "Súper")
["Leche", "Café", "Huevos", "Yerba"].each do |content|
  super_list.memory_list_items.find_or_create_by!(content: content)
end

work_list = demo_user.memory_lists.find_or_create_by!(title: "Trabajo")
["Enviar propuesta", "Revisar contrato", "Preparar briefing del lunes"].each do |content|
  work_list.memory_list_items.find_or_create_by!(content: content)
end

[
  {
    title: "DNI",
    content: "Mi DNI vence en agosto. Revisar renovación con tiempo.",
    source: "web"
  },
  {
    title: "Restaurante recomendado",
    content: "Juan recomendó reservar en Escaramuza para una cena tranquila.",
    source: "whatsapp"
  },
  {
    title: "Preferencia familiar",
    content: "A mamá le gusta recibir recordatorios temprano, antes de las 9.",
    source: "assistant"
  }
].each do |attributes|
  demo_user.memory_notes.find_or_create_by!(title: attributes[:title]) do |note|
    note.assign_attributes(attributes)
  end
end

[
  ["inbound", "Carlitos, recordame pagar el alquiler el viernes a las 10"],
  ["outbound", "Listo. Te aviso el viernes a las 10:00."],
  ["inbound", "Agregá café a la lista del súper"],
  ["outbound", "Agregué café a Súper."]
].each do |direction, body|
  demo_user.assistant_messages.find_or_create_by!(
    direction: direction,
    channel: "whatsapp",
    body: body
  ) do |message|
    message.metadata = { seeded: true }
  end
end

EarlyAccessSignup.find_or_create_by!(email: "early-demo@carlitos.test") do |signup|
  signup.name = "Early Demo"
end

puts "Seeded demo account:"
puts "  email: demo@carlitos.test"
puts "  password: password123"
puts "Seeded admin account:"
puts "  email: admin@carlitos.test"
puts "  password: password123"
