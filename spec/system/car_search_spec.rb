require "rails_helper"

RSpec.describe "Searching for a car by plate", type: :system do
  before { sign_in create(:user) }

  it "finds a car by partial plate and navigates to it" do
    client = create(:client, name: "João Silva")
    car = create(:car, plate: "AA-11-BB", brand: "Toyota", model: "Corolla", client: client)
    create(:car, plate: "CC-22-DD")

    visit clients_path
    find("[aria-label='#{I18n.t('nav.search')}']").click
    fill_in I18n.t("cars.search.placeholder"), with: "AA-1"

    within "#car_search_results" do
      expect(page).to have_content("AA-11-BB")
      expect(page).not_to have_content("CC-22-DD")
      click_on "AA-11-BB"
    end

    expect(page).to have_current_path(car_path(car))
    expect(page).to have_content("João Silva")
  end

  it "shows an empty state when no plate matches" do
    visit clients_path
    find("[aria-label='#{I18n.t('nav.search')}']").click
    fill_in I18n.t("cars.search.placeholder"), with: "ZZ-99"

    within "#car_search_results" do
      expect(page).to have_content(I18n.t("cars.search.no_results"))
    end
  end
end
