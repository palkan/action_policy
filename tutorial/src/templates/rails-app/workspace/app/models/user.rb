class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :tickets
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :agent_id
  has_many :comments

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, :email_address, presence: true

  def customer? = role == "customer"
  def agent? = role == "agent"
  def admin? = role == "admin"
end
