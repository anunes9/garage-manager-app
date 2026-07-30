require "rails_helper"

RSpec.describe "Managing account settings", type: :system do
  let!(:user) { create(:user, email: "manager@example.com", password: "password123", name: "Original Name") }

  before { sign_in user }

  it "updates the profile name and language" do
    visit edit_settings_path

    fill_in "Name", with: "New Name"
    select "Português", from: "Language"
    click_on "Save Profile"

    expect(page).to have_content("Perfil atualizado.")
    # The label itself is now in Portuguese since the language just switched,
    # so look the field up by its (locale-independent) id instead of label text.
    expect(page).to have_field("user_name", with: "New Name")
  end

  it "changes the password and can sign in with the new one" do
    visit edit_settings_path

    fill_in "Current Password", with: "password123"
    fill_in "New Password", with: "newpassword456"
    fill_in "Confirm New Password", with: "newpassword456"
    click_on "Change Password"

    expect(page).to have_content("Password updated.")

    click_on "Sign out"
    fill_in "Email", with: "manager@example.com"
    fill_in "Password", with: "newpassword456"
    click_on "Sign in"

    expect(page).to have_content("Clients")
  end

  it "shows an error for the wrong current password" do
    visit edit_settings_path

    fill_in "Current Password", with: "wrong-password"
    fill_in "New Password", with: "newpassword456"
    fill_in "Confirm New Password", with: "newpassword456"
    click_on "Change Password"

    expect(page).to have_content("is invalid")
  end
end
