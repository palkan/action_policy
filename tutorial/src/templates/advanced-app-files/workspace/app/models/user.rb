class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :tickets
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :agent_id
  has_many :comments

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, %w[customer agent admin].index_by(&:itself)

  validates :name, :email_address, presence: true
end
