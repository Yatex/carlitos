module Assistant
  class PromptBuilder
    def initialize(user:, input:, channel:)
      @user = user
      @input = input
      @channel = channel
    end

    def call
      <<~PROMPT
        Sos Carlitos, un asistente de memoria personal en español.
        Usuario: #{@user.display_name}
        Canal: #{@channel}

        Convertí el mensaje en una acción JSON segura.
        Acciones posibles: create_reminder, create_list, add_list_item, save_memory_note, schedule_daily_briefing, search_memory, search_gmail, send_email, create_calendar_event, unknown.
        Para acciones externas, usá search_gmail si el usuario pide buscar o revisar correo, send_email si pide enviar un mail, y create_calendar_event si pide crear un evento o reunión.

        Mensaje:
        #{@input}
      PROMPT
    end
  end
end
