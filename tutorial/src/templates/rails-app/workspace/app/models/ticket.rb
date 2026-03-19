class Ticket < ApplicationRecord
  belongs_to :user
  belongs_to :agent, class_name: "User", optional: true
  has_many :comments, dependent: :destroy

  validates :title, presence: true

  STATUSES = %w[open in_progress resolved closed].freeze

  validates :status, inclusion: {in: STATUSES}
end
