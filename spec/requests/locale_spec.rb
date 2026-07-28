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

  it "falls back to the default locale for an unknown ?locale instead of raising" do
    get clients_path(locale: "xx")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Clients")
  end

  it "ignores a non-scalar ?locale param" do
    get "/clients?locale[]=pt"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Clients")
  end
end
