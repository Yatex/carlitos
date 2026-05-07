module Assistant
  ActionResult = Struct.new(:success, :message, :record, keyword_init: true) do
    def success?
      success
    end
  end
end
