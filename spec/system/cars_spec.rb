require "rails_helper"

RSpec.describe "Managing cars", type: :system do
  before { sign_in create(:user) }

  it "creates a car for an existing client" do
    client = create(:client, name: "Dana")
    visit new_car_path

    select "Dana", from: "Client"
    fill_in "Brand", with: "Ford"
    fill_in "Model", with: "Focus"
    fill_in "Plate", with: "33-CC-33"
    click_on "Create Car"

    expect(page).to have_content("Car created")
    expect(page).to have_content("33-CC-33")
  end
end
