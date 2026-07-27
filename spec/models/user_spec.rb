require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with an email, password, and role" do
    user = build(:user)
    expect(user).to be_valid
  end

  it "defaults to the garage_manager role" do
    user = User.new
    expect(user.role).to eq("garage_manager")
  end

  it "is invalid without an email" do
    user = build(:user, email: nil)
    expect(user).not_to be_valid
  end

  describe "#admin?" do
    it "is true for admin-role users" do
      expect(build(:user, :admin).admin?).to be true
    end

    it "is false for garage_manager-role users" do
      expect(build(:user).admin?).to be false
    end
  end
end
