require "rails_helper"

RSpec.describe "Managing clients", type: :system do
  before { sign_in create(:user) }

  it "creates a client" do
    visit new_client_path

    fill_in "Nome", with: "Carol"
    fill_in "Telefone", with: "912345678"
    click_on "Criar Cliente"

    expect(page).to have_content("Cliente criado")
    expect(page).to have_content("Carol")
  end
end
