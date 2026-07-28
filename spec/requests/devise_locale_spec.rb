require "rails_helper"

RSpec.describe "Devise messages under ?locale=pt", type: :request do
  it "renders a real Portuguese message for a failed sign-in" do
    post user_session_path(locale: :pt), params: { user: { email: "nobody@example.com", password: "wrong" } }

    expect(response.body).to include("palavra-passe inválidos")
    expect(response.body).not_to include("translation missing")
  end

  it "renders the sign-in page without any 'translation missing' text" do
    get new_user_session_path(locale: :pt)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation missing")
  end

  it "has Portuguese text for Devise's authentication-required message" do
    expect(I18n.t("devise.failure.unauthenticated", locale: :pt))
      .to eq("Precisa de iniciar sessão ou registar-se antes de continuar.")
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
