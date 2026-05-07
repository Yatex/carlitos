class Reminder < ApplicationRecord
  belongs_to :user

  STATUSES = %w[pending completed canceled].freeze

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :upcoming, -> { where(status: "pending").order(Arel.sql("remind_at ASC NULLS LAST")) }
end
