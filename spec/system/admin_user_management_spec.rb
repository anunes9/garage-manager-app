require "rails_helper"

# Drives the real ActiveAdmin UI (docs/v2-design.md §9). This is also the regression test
# for ActiveAdmin's JavaScript actually loading under Propshaft: both the delete link and
# the logout link are `data-method="delete"` anchors that only work when Rails UJS is
# served and running (see config/initializers/active_admin.rb).
RSpec.describe "ActiveAdmin user management", type: :system do
  let(:admin) { create(:user, :admin, email: "boss@example.com") }

  before { sign_in admin }

  it "loads ActiveAdmin's JavaScript bundle" do
    visit "/admin/users"

    expect(page).to have_css("script[src*='jquery']", visible: :all)
    expect(page).to have_css("script[src*='rails-ujs']", visible: :all)
    expect(page).to have_css("script[src*='active_admin/base']", visible: :all)
    # jQuery, jQuery UI and ActiveAdmin's bundle all evaluated without error.
    expect(page.evaluate_script("typeof jQuery")).to eq("function")
    expect(page.evaluate_script("typeof jQuery.ui")).to eq("object")
    expect(page.evaluate_script("typeof Rails")).to eq("object")
    expect(page.evaluate_script("typeof ActiveAdmin")).to eq("object")
  end

  it "creates a user through the ActiveAdmin form" do
    visit "/admin/users"
    click_on "New User"

    fill_in "Name", with: "New Manager"
    fill_in "Email", with: "new.manager@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"
    select "garage_manager", from: "Role"
    click_on "Create User"

    expect(page).to have_content("new.manager@example.com")

    created = User.find_by(email: "new.manager@example.com")
    expect(created).to be_present
    expect(created.name).to eq("New Manager")
    expect(created.role).to eq("garage_manager")

    visit "/admin/users"
    expect(page).to have_content("new.manager@example.com")
  end

  it "edits a user's name through the ActiveAdmin form" do
    user = create(:user, name: "Old Name", email: "rename.me@example.com")

    visit edit_admin_user_path(user)
    fill_in "Name", with: "New Name"
    click_on "Update User"

    expect(page).to have_content("New Name")
    expect(user.reload.name).to eq("New Name")
  end

  it "deletes a user through the ActiveAdmin index delete link" do
    doomed = create(:user, email: "doomed@example.com")

    visit "/admin/users"
    expect(page).to have_content("doomed@example.com")

    within("#user_#{doomed.id}") do
      accept_confirm { click_on "Delete" }
    end

    expect(page).to have_no_content("doomed@example.com")
    expect(User.exists?(doomed.id)).to be(false)
  end

  it "signs out through the ActiveAdmin logout link" do
    visit "/admin/users"

    click_on "Logout"

    # Back at the Devise sign-in form, and really signed out.
    expect(page).to have_field("Email")
    visit clients_path
    expect(page).to have_current_path(new_user_session_path)
  end
end
