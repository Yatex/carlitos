module Assistant
  Decision = Struct.new(:action, :arguments, :confidence, :raw_input, keyword_init: true)
end
