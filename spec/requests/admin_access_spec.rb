require "rails_helper"

RSpec.describe "ActiveAdmin access", type: :request do
  it "denies a garage_manager" do
    sign_in create(:user)
    get "/admin/users"
    expect(response).to redirect_to(root_path)
  end

  it "denies a signed-out visitor" do
    get "/admin/users"
    expect(response).to redirect_to(new_user_session_path)
  end

  it "allows an admin" do
    sign_in create(:user, :admin)
    get "/admin/users"
    expect(response).to have_http_status(:ok)
  end
end
