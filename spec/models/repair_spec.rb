require "rails_helper"

RSpec.describe Repair, type: :model do
  it "is valid with a date, km, and a car" do
    expect(build(:repair)).to be_valid
  end

  it "is invalid without km" do
    expect(build(:repair, km: nil)).not_to be_valid
  end

  it "calculates total as the sum of price * quantity across its parts" do
    repair = create(:repair)
    repair.parts.create!(name: "Oil filter", quantity: 1, price: 10)
    repair.parts.create!(name: "Brake pad", quantity: 2, price: 25)
    repair.save!
    expect(repair.reload.total).to eq(60)
  end

  it "excludes parts marked for destruction from the total" do
    repair = create(:repair)
    part = repair.parts.create!(name: "Oil filter", quantity: 1, price: 10)
    repair.parts.create!(name: "Brake pad", quantity: 2, price: 25)
    repair.update!(parts_attributes: [ { id: part.id, _destroy: true } ])
    expect(repair.reload.total).to eq(50)
  end
end
