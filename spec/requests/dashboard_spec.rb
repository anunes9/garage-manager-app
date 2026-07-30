require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  before { sign_in create(:user) }

  it "shows KPI counts for clients, cars, total repairs, and repairs this month" do
    clients = create_list(:client, 2)
    cars = create_list(:car, 4, client: clients.first)
    create_list(:repair, 5, car: cars.first, date: Date.current)
    create_list(:repair, 2, car: cars.first, date: 1.month.ago.to_date)

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('class="stat-card__value">2<')
    expect(response.body).to include('class="stat-card__value">4<')
    expect(response.body).to include('class="stat-card__value">7<')
    expect(response.body).to include('class="stat-card__value">5<')
  end
end
