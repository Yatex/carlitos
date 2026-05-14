class TransactionalEmail
  class << self
    def welcome(user)
      escaped_name = ERB::Util.html_escape(user.display_name)
      ResendClient.new.send_email(
        to: user.email,
        subject: I18n.t("emails.welcome.subject"),
        html: I18n.t("emails.welcome.html", name: escaped_name),
        text: I18n.t("emails.welcome.text", name: user.display_name)
      )
    end

    def password_reset(user, reset_url)
      escaped_url = ERB::Util.html_escape(reset_url)
      ResendClient.new.send_email(
        to: user.email,
        subject: I18n.t("emails.password_reset.subject"),
        html: I18n.t("emails.password_reset.html", url: escaped_url),
        text: I18n.t("emails.password_reset.text", url: reset_url)
      )
    end

    def early_access_confirmation(signup)
      ResendClient.new.send_email(
        to: signup.email,
        subject: I18n.t("emails.early_access.subject"),
        html: I18n.t("emails.early_access.html"),
        text: I18n.t("emails.early_access.text")
      )
    end
  end
end
