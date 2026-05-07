class MemoryNote < ApplicationRecord
  belongs_to :user

  SOURCES = %w[web whatsapp email assistant voice].freeze

  validates :title, :content, presence: true
  validates :source, inclusion: { in: SOURCES }

  scope :recent, -> { order(created_at: :desc) }
end
