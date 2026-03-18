class Product < ApplicationRecord
  validates :name, presence: true
end
