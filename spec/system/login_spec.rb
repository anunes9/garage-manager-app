require "rails_helper"

# Exercises the real Devise sign-in form (no `sign_in` test helper), as called for by
# docs/v2-design.md §9.
RSpec.describe "Logging in", type: :system do
  let!(:user) { create(:user, email: "manager@example.com", password: "password123") }

  it "signs in with valid credentials and lands on the clients index" do
    visit new_user_session_path

    fill_in "Email", with: "manager@example.com"
    fill_in "Password", with: "password123"
    click_on "Log in"

    expect(page).to have_current_path(clients_path)
    expect(page).to have_content("Clients")
    within("nav") { expect(page).to have_content("manager@example.com") }
  end

  it "shows an error and stays signed out with a wrong password" do
    visit new_user_session_path

    fill_in "Email", with: "manager@example.com"
    fill_in "Password", with: "wrong-password"
    click_on "Log in"

    expect(page).to have_content("Invalid email or password")
    expect(page).to have_no_css("nav")
  end

  it "signs out again" do
    visit new_user_session_path
    fill_in "Email", with: "manager@example.com"
    fill_in "Password", with: "password123"
    click_on "Log in"
    expect(page).to have_content("Clients")

    click_on "Sign out"

    expect(page).to have_field("Email")
    expect(page).to have_no_css("nav")
  end
end
