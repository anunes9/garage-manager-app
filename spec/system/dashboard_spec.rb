require "rails_helper"

RSpec.describe "Dashboard quick actions", type: :system do
  before { sign_in create(:user) }

  it "opens the new client form" do
    visit root_path
    click_on I18n.t("clients.new")
    expect(page).to have_current_path(new_client_path)
  end

  it "opens the new car form" do
    visit root_path
    click_on I18n.t("cars.new")
    expect(page).to have_current_path(new_car_path)
  end

  it "opens the new repair form" do
    visit root_path
    click_on I18n.t("repairs.new")
    expect(page).to have_current_path(new_repair_path)
  end

  it "opens the car search page" do
    visit root_path
    click_on I18n.t("nav.search")
    expect(page).to have_current_path(search_cars_path)
  end

  it "is reachable from a Home link in the nav" do
    visit clients_path
    click_on I18n.t("nav.home")
    expect(page).to have_current_path(root_path)
  end
end
