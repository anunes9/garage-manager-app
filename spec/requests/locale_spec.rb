require "rails_helper"

RSpec.describe "Locale switching", type: :request do
  before { sign_in create(:user) }

  it "renders English by default" do
    get clients_path
    expect(response.body).to include("Clients")
  end

  it "renders Portuguese when ?locale=pt" do
    get clients_path(locale: :pt)
    expect(response.body).to include("Clientes")
  end
end
