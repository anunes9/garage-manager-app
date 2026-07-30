class Car < ApplicationRecord
  belongs_to :client
  has_many :repairs, dependent: :destroy

  validates :brand, presence: true
  validates :model, presence: true
  validates :plate, presence: true, uniqueness: true

  # Used by ActiveAdmin's belongs_to select inputs (e.g. Repair's Car picker).
  def to_s
    "#{plate} — #{brand} #{model}"
  end

  # Ransack (used by ActiveAdmin's index filters) requires an explicit allowlist of
  # searchable attributes/associations.
  def self.ransackable_attributes(auth_object = nil)
    %w[id brand model plate vin motor year month notes client_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[client repairs]
  end
end
