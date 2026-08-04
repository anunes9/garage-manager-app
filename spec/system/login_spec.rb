require "rails_helper"

# Exercises the real Devise sign-in form (no `sign_in` test helper), as called for by
# docs/v2-design.md §9.
RSpec.describe "Logging in", type: :system do
  let!(:user) { create(:user, email: "manager@example.com", password: "password123") }

  it "signs in with valid credentials and lands on the dashboard" do
    visit new_user_session_path

    fill_in "Endereço de email", with: "manager@example.com"
    fill_in "Palavra-passe", with: "password123"
    click_on "Iniciar sessão"

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Painel")
    within("nav") { expect(page).to have_content("manager@example.com") }
  end

  it "shows an error and stays signed out with a wrong password" do
    visit new_user_session_path

    fill_in "Endereço de email", with: "manager@example.com"
    fill_in "Palavra-passe", with: "wrong-password"
    click_on "Iniciar sessão"

    expect(page).to have_content("Email ou palavra-passe inválidos")
    expect(page).to have_no_css("nav")
  end

  it "signs out again" do
    visit new_user_session_path
    fill_in "Endereço de email", with: "manager@example.com"
    fill_in "Palavra-passe", with: "password123"
    click_on "Iniciar sessão"
    expect(page).to have_content("Clientes")

    click_on "Sair"

    expect(page).to have_field("Endereço de email")
    expect(page).to have_no_css("nav")
  end
end
