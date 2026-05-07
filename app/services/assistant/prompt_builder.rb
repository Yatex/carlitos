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
        Acciones posibles: create_reminder, create_list, add_list_item, save_memory_note, schedule_daily_briefing, search_memory, unknown.

        Mensaje:
        #{@input}
      PROMPT
    end
  end
end
