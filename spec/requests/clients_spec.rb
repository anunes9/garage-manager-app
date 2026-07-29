require "rails_helper"

RSpec.describe "Clients", type: :request do
  before { sign_in create(:user) }

  it "lists clients" do
    client = create(:client, name: "Alice")
    get clients_path
    expect(response.body).to include("Alice")
  end

  it "creates a client" do
    expect {
      post clients_path, params: { client: { name: "Bob", phone: "912345678" } }
    }.to change(Client, :count).by(1)
    expect(response).to redirect_to(client_path(Client.last))
  end

  it "rejects an invalid client" do
    expect {
      post clients_path, params: { client: { name: "", phone: "" } }
    }.not_to change(Client, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "updates a client" do
    client = create(:client)
    patch client_path(client), params: { client: { name: "Updated Name" } }
    expect(client.reload.name).to eq("Updated Name")
  end

  it "destroys a client" do
    client = create(:client)
    expect { delete client_path(client) }.to change(Client, :count).by(-1)
  end

  it "shows the plate search control in the nav" do
    get clients_path
    expect(response.body).to include(I18n.t("nav.search"))
  end

  it "links the account identity in the nav to the settings page" do
    sign_in create(:user, name: "Ana")
    get clients_path
    expect(response.body).to include(edit_settings_path)
    expect(response.body).to include("Ana")
  end

  it "falls back to email in the nav when the user has no name" do
    user = create(:user, name: nil)
    sign_in user
    get clients_path
    expect(response.body).to include(user.email)
  end
end
