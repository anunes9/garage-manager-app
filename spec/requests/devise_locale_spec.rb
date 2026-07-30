require "rails_helper"

RSpec.describe "Devise pages before sign-in", type: :request do
  it "renders the sign-in page in English (no current_user yet to read a locale from)" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation missing")
  end

  it "renders an English message for a failed sign-in" do
    post user_session_path, params: { user: { email: "nobody@example.com", password: "wrong" } }

    expect(response.body).to include("Invalid email or password.")
  end

  it "falls back to English rather than rendering 'translation missing'" do
    I18n.with_locale(:pt) do
      # A key that only exists in English (Rails' own error messages are not translated
      # to Portuguese in this app), so it must fall back instead of blowing up.
      expect(I18n.t("errors.messages.blank")).to eq("can't be blank")
      expect(I18n.t("devise.sessions.signed_out")).to eq("Sessão terminada com sucesso.")
    end
  end
end
