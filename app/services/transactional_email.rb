class TransactionalEmail
  class << self
    def welcome(user)
      ResendClient.new.send_email(
        to: user.email,
        subject: "Bienvenido a Carlitos",
        html: "<p>Hola #{ERB::Util.html_escape(user.display_name)},</p><p>Carlitos ya está listo para ayudarte a recordar menos cosas de memoria.</p>",
        text: "Hola #{user.display_name}, Carlitos ya está listo para ayudarte a recordar menos cosas de memoria."
      )
    end

    def password_reset(user, reset_url)
      ResendClient.new.send_email(
        to: user.email,
        subject: "Recuperá tu contraseña de Carlitos",
        html: "<p>Usá este enlace para crear una nueva contraseña:</p><p><a href=\"#{ERB::Util.html_escape(reset_url)}\">Cambiar contraseña</a></p>",
        text: "Usá este enlace para crear una nueva contraseña: #{reset_url}"
      )
    end

    def early_access_confirmation(signup)
      ResendClient.new.send_email(
        to: signup.email,
        subject: "Te sumamos al acceso anticipado de Carlitos",
        html: "<p>Gracias por querer probar Carlitos. Te vamos a avisar cuando abramos el acceso.</p>",
        text: "Gracias por querer probar Carlitos. Te vamos a avisar cuando abramos el acceso."
      )
    end
  end
end
