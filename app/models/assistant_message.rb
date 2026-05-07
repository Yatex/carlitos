class AssistantMessage < ApplicationRecord
  belongs_to :user

  DIRECTIONS = %w[inbound outbound].freeze
  CHANNELS = %w[web whatsapp email].freeze

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :channel, inclusion: { in: CHANNELS }
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
