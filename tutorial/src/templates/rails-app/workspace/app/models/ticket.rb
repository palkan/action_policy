class Ticket < ApplicationRecord
  belongs_to :user
  belongs_to :agent, class_name: "User", optional: true
  has_many :comments, dependent: :destroy

  validates :title, presence: true

  enum :status, %w[open in_progress resolved closed].index_by(&:itself)
end
