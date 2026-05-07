class DailyBriefing < ApplicationRecord
  belongs_to :user

  before_validation :set_defaults
  before_validation :normalize_timezone

  validates :delivery_time, :timezone, presence: true
  validate :timezone_must_be_valid

  private

  def set_defaults
    self.delivery_time ||= "08:00"
    self.timezone = timezone.presence || user&.timezone || "America/Montevideo"
  end

  def normalize_timezone
    zone = ActiveSupport::TimeZone[timezone]
    self.timezone = zone.tzinfo.identifier if zone
  end

  def timezone_must_be_valid
    errors.add(:timezone, "no es válida") unless ActiveSupport::TimeZone[timezone]
  end
end
