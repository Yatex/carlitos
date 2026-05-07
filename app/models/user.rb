class User < ApplicationRecord
  has_secure_password
  has_secure_token :password_reset_token

  SUBSCRIPTION_STATUSES = %w[free trialing active past_due canceled incomplete].freeze
  PLANS = %w[free pro family].freeze

  enum role: { user: 0, admin: 1, super_admin: 2 }

  has_many :reminders, dependent: :destroy
  has_many :memory_lists, dependent: :destroy
  has_many :memory_notes, dependent: :destroy
  has_one :daily_briefing, dependent: :destroy
  has_many :assistant_messages, dependent: :destroy
  has_many :assistant_runs, dependent: :destroy
  has_many :integration_connections, dependent: :destroy
  belongs_to :plan_granted_by, class_name: "User", optional: true
  has_many :granted_plan_users, class_name: "User", foreign_key: :plan_granted_by_id, dependent: :nullify, inverse_of: :plan_granted_by

  before_validation :normalize_email
  before_validation :set_defaults
  before_validation :normalize_timezone
  after_create :ensure_daily_briefing

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :timezone, presence: true
  validate :timezone_must_be_valid
  validates :subscription_status, inclusion: { in: SUBSCRIPTION_STATUSES }
  validates :current_plan, inclusion: { in: PLANS }

  def display_name
    name.presence || email.split("@").first
  end

  def paid?
    current_plan.in?(%w[pro family]) && subscription_status.in?(%w[trialing active]) && plan_access_active?
  end

  def admin_like?
    admin? || super_admin?
  end

  def plan_access_active?
    plan_expires_at.blank? || plan_expires_at.future?
  end

  def plan_expires_on
    plan_expires_at&.to_date
  end

  def prepare_password_reset!
    regenerate_password_reset_token
    update!(password_reset_sent_at: Time.current)
  end

  def password_reset_expired?
    password_reset_sent_at.blank? || password_reset_sent_at < 2.hours.ago
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def set_defaults
    self.timezone = timezone.presence || "America/Montevideo"
    self.subscription_status = subscription_status.presence || "free"
    self.current_plan = current_plan.presence || "free"
    self.role = role.presence || "user"
  end

  def normalize_timezone
    zone = ActiveSupport::TimeZone[timezone]
    self.timezone = zone.tzinfo.identifier if zone
  end

  def timezone_must_be_valid
    errors.add(:timezone, "no es válida") unless ActiveSupport::TimeZone[timezone]
  end

  def ensure_daily_briefing
    create_daily_briefing!(timezone:) unless daily_briefing
  end
end
