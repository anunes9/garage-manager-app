require "rails_helper"

RSpec.describe Client, type: :model do
  it "is valid with a name and 9-digit phone" do
    expect(build(:client)).to be_valid
  end

  it "is invalid without a name" do
    expect(build(:client, name: nil)).not_to be_valid
  end

  it "is invalid with a phone that isn't 9 characters" do
    expect(build(:client, phone: "123")).not_to be_valid
  end

  it "destroys its cars when destroyed" do
    client = create(:client)
    car = create(:car, client: client)
    expect { client.destroy }.to change(Car, :count).by(-1)
    expect { car.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
