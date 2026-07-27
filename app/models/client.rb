class Client < ApplicationRecord
  has_many :cars, dependent: :destroy

  validates :name, presence: true
  validates :phone, presence: true, length: { is: 9 }
end
