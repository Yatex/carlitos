class AssistantRun < ApplicationRecord
  belongs_to :user

  STATUSES = %w[pending completed failed].freeze

  validates :input, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
end
