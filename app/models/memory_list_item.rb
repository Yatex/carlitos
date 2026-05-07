class MemoryListItem < ApplicationRecord
  belongs_to :memory_list

  validates :content, presence: true

  scope :open, -> { where(completed_at: nil) }

  def completed?
    completed_at.present?
  end
end
