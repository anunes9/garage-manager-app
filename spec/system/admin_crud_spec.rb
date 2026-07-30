require "rails_helper"

RSpec.describe "ActiveAdmin clients/cars/repairs management", type: :system do
  let(:admin) { create(:user, :admin, email: "boss@example.com") }

  before { sign_in admin }

  it "creates a client through the ActiveAdmin form" do
    visit "/admin/clients"
    click_on "New Client"

    fill_in "Name", with: "New Client"
    fill_in "Phone", with: "912345678"
    click_on "Create Client"

    expect(page).to have_content("Client was successfully created")
    expect(page).to have_content("New Client")
  end

  it "deletes a client through the ActiveAdmin index delete link" do
    doomed = create(:client, name: "Doomed Client")

    visit "/admin/clients"
    expect(page).to have_content("Doomed Client")

    within("#client_#{doomed.id}") do
      accept_confirm { click_on "Delete" }
    end

    expect(page).to have_no_content("Doomed Client")
    expect(Client.exists?(doomed.id)).to be(false)
  end

  it "creates a car through the ActiveAdmin form" do
    client = create(:client)

    visit "/admin/cars"
    click_on "New Car"

    select client.name, from: "Client"
    fill_in "Brand", with: "Honda"
    fill_in "Model", with: "Civic"
    fill_in "Plate", with: "ZZ-99-ZZ"
    click_on "Create Car"

    expect(page).to have_content("Car was successfully created")
    expect(page).to have_content("ZZ-99-ZZ")
  end

  it "creates a repair with parts through the ActiveAdmin form" do
    car = create(:car)

    visit "/admin/repairs"
    click_on "New Repair"

    select car.to_s, from: "Car"
    select Date.current.year.to_s, from: "repair_date_1i"
    select Date::MONTHNAMES[Date.current.month], from: "repair_date_2i"
    select Date.current.day.to_s, from: "repair_date_3i"
    fill_in "Km", with: "1000"
    click_on "Add New Part"
    expect(page).to have_css(".has_many_container.parts .has_many_fields")
    within all(".has_many_container.parts .has_many_fields").last do
      fill_in "Name", with: "Oil filter"
      fill_in "Quantity", with: "2"
      fill_in "Price", with: "10.5"
    end
    click_on "Create Repair"

    expect(page).to have_content("Repair was successfully created")
    expect(page).to have_content("Oil filter")
    expect(page).to have_content("21.0")
  end
end
