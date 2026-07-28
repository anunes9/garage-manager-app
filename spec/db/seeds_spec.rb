require "rails_helper"

RSpec.describe "db/seeds.rb", type: :model do
  it "is a no-op outside development" do
    expect(Rails.env).to eq("test")

    expect {
      expect { load Rails.root.join("db/seeds.rb") }.to output(/Skipping db\/seeds\.rb/).to_stdout
    }.not_to change(User, :count)

    expect(User.exists?(email: "admin@example.com")).to be(false)
  end
end
