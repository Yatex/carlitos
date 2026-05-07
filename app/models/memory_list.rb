class MemoryList < ApplicationRecord
  belongs_to :user
  has_many :memory_list_items, dependent: :destroy

  validates :title, presence: true

  scope :recent, -> { order(updated_at: :desc) }
end
