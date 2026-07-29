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
    fill_in "VIN", with: "WF0AXXGCDA1B23456"
    fill_in "Engine", with: "1.5 EcoBoost"
    click_on "Create Car"

    expect(page).to have_content("Car created")
    expect(page).to have_content("33-CC-33")
    expect(page).to have_content("WF0AXXGCDA1B23456")
    expect(page).to have_content("1.5 EcoBoost")
  end

  it "starts a new car for a client from its show page with the client preselected" do
    client = create(:client, name: "Elena Rocha")
    visit client_path(client)

    click_on "New Car"

    expect(page).to have_select("Client", selected: "Elena Rocha")
  end
end
