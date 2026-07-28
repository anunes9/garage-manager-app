require "rails_helper"

RSpec.describe "Managing repairs", type: :system do
  before { sign_in create(:user) }

  it "creates a repair with two dynamically-added parts" do
    car = create(:car, plate: "55-EE-55")
    visit new_repair_path

    select "55-EE-55", from: "Car"
    fill_in "Date", with: Date.current
    fill_in "Km", with: 1000

    click_on "Add Part"
    within all(".part-fields").last do
      fill_in "Name", with: "Oil filter"
      fill_in "Qty", with: 1
      fill_in "Price", with: 10
    end

    click_on "Add Part"
    within all(".part-fields").last do
      fill_in "Name", with: "Brake pad"
      fill_in "Qty", with: 2
      fill_in "Price", with: 25
    end

    click_on "Create Repair"

    expect(page).to have_content("Repair created")
    expect(page).to have_content("60.0€")
  end
end
