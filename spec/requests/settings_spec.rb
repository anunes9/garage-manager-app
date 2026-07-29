require "rails_helper"

RSpec.describe "Settings", type: :request do
  let(:user) { create(:user, name: "Original", locale: "en", password: "password123") }

  before { sign_in user }

  it "updates the profile name and locale" do
    patch settings_path, params: { user: { name: "Updated Name", locale: "pt" } }

    expect(response).to redirect_to(edit_settings_path)
    user.reload
    expect(user.name).to eq("Updated Name")
    expect(user.locale).to eq("pt")
  end

  it "rejects an invalid locale" do
    patch settings_path, params: { user: { name: "Updated Name", locale: "xx" } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(user.reload.name).not_to eq("Updated Name")
  end
end
