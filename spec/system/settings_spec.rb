require "rails_helper"

RSpec.describe "Managing account settings", type: :system do
  let!(:user) { create(:user, email: "manager@example.com", password: "password123", name: "Original Name") }

  before { sign_in user }

  it "updates the profile name and language" do
    visit edit_settings_path

    fill_in "Nome", with: "New Name"
    select "Português", from: "Idioma"
    click_on "Guardar Perfil"

    expect(page).to have_content("Perfil atualizado.")
    expect(page).to have_field("user_name", with: "New Name")
  end

  it "changes the password and can sign in with the new one" do
    visit edit_settings_path

    fill_in "Palavra-passe Atual", with: "password123"
    fill_in "Nova Palavra-passe", with: "newpassword456"
    fill_in "Confirmar Nova Palavra-passe", with: "newpassword456"
    click_on "Alterar Palavra-passe"

    expect(page).to have_content("Palavra-passe atualizada.")

    click_on "Sair"
    fill_in "Endereço de email", with: "manager@example.com"
    fill_in "Palavra-passe", with: "newpassword456"
    click_on "Iniciar sessão"

    expect(page).to have_content("Clientes")
  end

  it "shows an error for the wrong current password" do
    visit edit_settings_path

    fill_in "Palavra-passe Atual", with: "wrong-password"
    fill_in "Nova Palavra-passe", with: "newpassword456"
    fill_in "Confirmar Nova Palavra-passe", with: "newpassword456"
    click_on "Alterar Palavra-passe"

    expect(page).to have_content("is invalid")
  end
end
