require "rails_helper"

RSpec.describe Part, type: :model do
  it "is valid with a name, quantity, price, and repair" do
    expect(build(:part)).to be_valid
  end

  it "is invalid with a zero quantity" do
    expect(build(:part, quantity: 0)).not_to be_valid
  end

  it "is invalid with a negative price" do
    expect(build(:part, price: -1)).not_to be_valid
  end
end
