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

  it "changes the password with the correct current password" do
    patch settings_password_path, params: {
      user: { current_password: "password123", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    expect(response).to redirect_to(edit_settings_path)
    expect(user.reload.valid_password?("newpassword456")).to be true
  end

  it "keeps the user signed in after a password change" do
    patch settings_password_path, params: {
      user: { current_password: "password123", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    get edit_settings_path
    expect(response).to have_http_status(:ok)
  end

  it "rejects the wrong current password" do
    patch settings_password_path, params: {
      user: { current_password: "wrong", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(user.reload.valid_password?("newpassword456")).to be false
  end

  it "rejects a blank new password" do
    patch settings_password_path, params: {
      user: { current_password: "password123", password: "", password_confirmation: "" }
    }

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
