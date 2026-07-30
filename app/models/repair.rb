class Repair < ApplicationRecord
  belongs_to :car
  has_many :parts, dependent: :destroy
  accepts_nested_attributes_for :parts, allow_destroy: true, reject_if: :all_blank

  validates :date, presence: true
  validates :km, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total

  # Ransack (used by ActiveAdmin's index filters) requires an explicit allowlist of
  # searchable attributes/associations.
  def self.ransackable_attributes(auth_object = nil)
    %w[id date km notes total car_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[car parts]
  end

  private

  def calculate_total
    self.total = parts.reject(&:marked_for_destruction?)
                       .sum { |part| part.price.to_f * part.quantity.to_i }
  end
end
