require "rails_helper"

RSpec.describe "Locale switching", type: :request do
  it "renders English by default" do
    sign_in create(:user)
    get clients_path
    expect(response.body).to include("Clients")
  end

  it "renders Portuguese for a user whose locale is pt" do
    sign_in create(:user, locale: "pt")
    get clients_path
    expect(response.body).to include("Clientes")
  end

  it "ignores a ?locale param now that locale is a per-user setting" do
    sign_in create(:user, locale: "pt")
    get clients_path(locale: "en")
    expect(response.body).to include("Clientes")
  end

  it "translates form submit buttons instead of falling back to Rails' English default" do
    sign_in create(:user, locale: "pt")

    get new_client_path
    expect(response.body).to include("Criar Cliente")

    get new_car_path
    expect(response.body).to include("Criar Carro")

    get new_repair_path
    expect(response.body).to include("Criar Reparação")
  end
end
