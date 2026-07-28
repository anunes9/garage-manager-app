class Repair < ApplicationRecord
  belongs_to :car
  has_many :parts, dependent: :destroy
  accepts_nested_attributes_for :parts, allow_destroy: true, reject_if: :all_blank

  validates :date, presence: true
  validates :km, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total

  private

  def calculate_total
    self.total = parts.reject(&:marked_for_destruction?)
                       .sum { |part| part.price.to_f * part.quantity.to_i }
  end
end
