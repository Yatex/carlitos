require "base64"
require "mail"

module Integrations
  module Google
    class GmailClient
      API_BASE = "https://gmail.googleapis.com/gmail/v1/users/me".freeze

      def initialize(user:, api_client: Integrations::GoogleApiClient.new(user: user, provider: "gmail"))
        @user = user
        @api_client = api_client
      end

      def search(query:, max_results: 5)
        list = @api_client.get("#{API_BASE}/messages", params: { q: query.presence || "newer_than:7d", maxResults: max_results })
        Array(list["messages"]).first(max_results).map do |message|
          message_metadata(message["id"])
        end
      end

      def send_email(to:, subject:, body:, cc: nil, bcc: nil)
        mail = Mail.new
        mail.to = to
        mail.cc = cc if cc.present?
        mail.bcc = bcc if bcc.present?
        mail.from = @user.email
        mail.subject = subject
        mail.text_part = Mail::Part.new(body: body)

        raw = Base64.urlsafe_encode64(mail.encoded).delete("=")
        @api_client.post_json("#{API_BASE}/messages/send", { raw: raw })
      end

      private

      def message_metadata(id)
        query = URI.encode_www_form([
          ["format", "metadata"],
          ["metadataHeaders", "From"],
          ["metadataHeaders", "Subject"],
          ["metadataHeaders", "Date"]
        ])
        response = @api_client.get(
          "#{API_BASE}/messages/#{id}?#{query}"
        )
        headers = Array(response.dig("payload", "headers")).index_by { |header| header["name"].to_s.downcase }
        {
          id: response["id"],
          subject: headers.dig("subject", "value").presence || "(sin asunto)",
          from: headers.dig("from", "value"),
          date: headers.dig("date", "value"),
          snippet: response["snippet"]
        }
      end
    end
  end
end
