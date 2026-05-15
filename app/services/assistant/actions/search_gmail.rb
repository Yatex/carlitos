module Assistant
  module Actions
    class SearchGmail
      def initialize(user:, arguments:)
        @user = user
        @arguments = arguments
      end

      def call
        query = @arguments["query"].presence || @arguments["search"].presence || "newer_than:7d"
        results = Integrations::Google::GmailClient.new(user: @user).search(query:, max_results: max_results)

        if results.empty?
          return ActionResult.new(success: true, message: I18n.t("assistant.actions.search_gmail.not_found"), record: results)
        end

        summary = results.first(3).map { |message| email_summary(message) }.join("; ")
        ActionResult.new(success: true, message: I18n.t("assistant.actions.search_gmail.found", emails: summary), record: results)
      rescue Integrations::GoogleApiClient::MissingConnection, Integrations::GoogleApiClient::MissingToken
        ActionResult.new(success: false, message: I18n.t("assistant.actions.search_gmail.connect_gmail"))
      rescue Integrations::GoogleApiClient::Error => e
        ActionResult.new(success: false, message: I18n.t("assistant.actions.search_gmail.failed", error: e.message))
      end

      private

      def max_results
        value = @arguments["max_results"].presence || @arguments["limit"].presence || 5
        value.to_i.clamp(1, 10)
      end

      def email_summary(message)
        [
          message[:subject],
          message[:from]
        ].compact_blank.join(" - ")
      end
    end
  end
end
