require "rails_helper"

RSpec.describe "Managing repairs", type: :system do
  before { sign_in create(:user) }

  it "creates a repair with two dynamically-added parts" do
    car = create(:car, plate: "55-EE-55")
    visit new_repair_path

    select "55-EE-55", from: "Carro"
    fill_in "Data", with: Date.current
    fill_in "Km", with: 1000

    click_on "Adicionar Peça"
    within all(".part-fields").last do
      fill_in "Nome", with: "Oil filter"
      fill_in "Qtd", with: 1
      fill_in "Preço", with: 10
    end

    click_on "Adicionar Peça"
    within all(".part-fields").last do
      fill_in "Nome", with: "Brake pad"
      fill_in "Qtd", with: 2
      fill_in "Preço", with: 25
    end

    click_on "Criar Reparação"

    expect(page).to have_content("Reparação criada.")
    expect(page).to have_content("60.00€")
  end

  it "starts a new repair for a car from its show page with the car and today's date preselected" do
    car = create(:car, plate: "66-FF-66")
    visit car_path(car)

    click_on "Nova Reparação"

    expect(page).to have_select("Carro", selected: "66-FF-66")
    expect(page).to have_field("Data", with: Date.current.iso8601)
  end
end
