require "rails_helper"

RSpec.describe Car, type: :model do
  it "is valid with brand, model, plate, and a client" do
    expect(build(:car)).to be_valid
  end

  it "is invalid without a plate" do
    expect(build(:car, plate: nil)).not_to be_valid
  end

  it "is invalid with a duplicate plate" do
    create(:car, plate: "AA-11-BB")
    expect(build(:car, plate: "AA-11-BB")).not_to be_valid
  end

  it "is invalid without a client" do
    expect(build(:car, client: nil)).not_to be_valid
  end
end
