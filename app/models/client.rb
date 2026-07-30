class Client < ApplicationRecord
  has_many :cars, dependent: :destroy

  validates :name, presence: true
  validates :phone, presence: true, length: { is: 9 }

  # Ransack (used by ActiveAdmin's index filters) requires an explicit allowlist of
  # searchable attributes/associations.
  def self.ransackable_attributes(auth_object = nil)
    %w[id name phone created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[cars]
  end
end
