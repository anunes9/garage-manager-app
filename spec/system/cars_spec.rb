require "rails_helper"

RSpec.describe "Managing cars", type: :system do
  before { sign_in create(:user) }

  it "creates a car for an existing client" do
    client = create(:client, name: "Dana")
    visit new_car_path

    select "Dana", from: "Cliente"
    fill_in "Marca", with: "Ford"
    fill_in "Modelo", with: "Focus"
    fill_in "Matrícula", with: "33-CC-33"
    fill_in "Nº de Chassis (VIN)", with: "WF0AXXGCDA1B23456"
    fill_in "Motor", with: "1.5 EcoBoost"
    click_on "Criar Carro"

    expect(page).to have_content("Carro criado.")
    expect(page).to have_content("33-CC-33")
    expect(page).to have_content("WF0AXXGCDA1B23456")
    expect(page).to have_content("1.5 EcoBoost")
  end

  it "starts a new car for a client from its show page with the client preselected" do
    client = create(:client, name: "Elena Rocha")
    visit client_path(client)

    click_on "Novo Carro"

    expect(page).to have_select("Cliente", selected: "Elena Rocha")
  end
end
