class IntegrationConnection < ApplicationRecord
  PROVIDERS = %w[gmail google_calendar whatsapp].freeze
  STATUSES = %w[disconnected pending connected error].freeze

  belongs_to :user

  before_validation :set_defaults

  validates :provider, inclusion: { in: PROVIDERS }, uniqueness: { scope: :user_id }
  validates :status, inclusion: { in: STATUSES }

  scope :connected, -> { where(status: "connected") }

  def connected?
    status == "connected"
  end

  def pending?
    status == "pending"
  end

  def disconnected?
    status == "disconnected"
  end

  private

  def set_defaults
    self.status = status.presence || "disconnected"
    self.metadata ||= {}
  end
end
