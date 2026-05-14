module Authentication
  class GoogleAccountProvisioner
    Result = Data.define(:user, :created)
    ProvisionError = Class.new(StandardError)

    def call(profile:, timezone: nil)
      normalized_profile = profile.with_indifferent_access
      email = normalized_profile[:email].to_s.strip.downcase
      google_uid = normalized_profile[:sub].to_s.presence
      verified = truthy?(normalized_profile[:email_verified])

      raise ProvisionError, I18n.t("auth_services.google.invalid_email") if email.blank?
      raise ProvisionError, I18n.t("auth_services.google.unverified_email") unless verified

      user = find_user(email:, google_uid:)
      if user
        update_google_link!(user, normalized_profile, google_uid, verified)
        Result.new(user:, created: false)
      else
        user = create_user!(normalized_profile, email, google_uid, verified, timezone)
        TransactionalEmail.welcome(user)
        Result.new(user:, created: true)
      end
    end

    private

    def find_user(email:, google_uid:)
      User.find_by(google_uid: google_uid) || User.find_by(email: email)
    end

    def update_google_link!(user, profile, google_uid, verified)
      if user.google_uid.present? && google_uid.present? && user.google_uid != google_uid
        raise ProvisionError, I18n.t("auth_services.google.email_linked")
      end

      user.update!(
        google_uid: user.google_uid.presence || google_uid,
        google_email_verified: verified,
        google_connected_at: Time.current,
        name: user.name.presence || profile[:name].presence
      )
    end

    def create_user!(profile, email, google_uid, verified, timezone)
      password = SecureRandom.base58(32)
      User.create!(
        email: email,
        name: profile[:name].presence || email.split("@").first,
        timezone: valid_timezone(timezone) || "America/Montevideo",
        google_uid: google_uid,
        google_email_verified: verified,
        google_connected_at: Time.current,
        password: password,
        password_confirmation: password
      )
    end

    def valid_timezone(value)
      return nil if value.blank?

      zone = ActiveSupport::TimeZone[value]
      zone&.tzinfo&.identifier
    end

    def truthy?(value)
      value == true || value.to_s == "true"
    end
  end
end
