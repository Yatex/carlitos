module Assistant
  module Actions
    class SendEmail
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        to = @arguments["to"].presence || @arguments["recipient"].presence
        subject = @arguments["subject"].presence || I18n.t("assistant.actions.send_email.default_subject")
        body = @arguments["body"].presence || @arguments["message"].presence

        unless to.present? && URI::MailTo::EMAIL_REGEXP.match?(to) && body.present?
          return ActionResult.new(success: false, message: I18n.t("assistant.actions.send_email.missing_fields"))
        end

        result = Integrations::Google::GmailClient.new(user: @user).send_email(
          to: to,
          subject: subject,
          body: body,
          cc: @arguments["cc"],
          bcc: @arguments["bcc"]
        )
        ActionResult.new(success: true, message: I18n.t("assistant.actions.send_email.sent", email: to), record: result)
      rescue Integrations::GoogleApiClient::MissingConnection, Integrations::GoogleApiClient::MissingToken
        ActionResult.new(success: false, message: I18n.t("assistant.actions.send_email.connect_gmail"))
      rescue Integrations::GoogleApiClient::Error => e
        ActionResult.new(success: false, message: I18n.t("assistant.actions.send_email.failed", error: e.message))
      end
    end
  end
end
