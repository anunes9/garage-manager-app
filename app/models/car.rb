class Car < ApplicationRecord
  belongs_to :client
  has_many :repairs, dependent: :destroy

  validates :brand, presence: true
  validates :model, presence: true
  validates :plate, presence: true, uniqueness: true
end
