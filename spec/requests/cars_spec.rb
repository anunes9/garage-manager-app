require "rails_helper"

RSpec.describe "Cars", type: :request do
  before { sign_in create(:user) }

  it "lists cars" do
    car = create(:car, plate: "11-AA-11")
    get cars_path
    expect(response.body).to include("11-AA-11")
  end

  it "creates a car for a client" do
    client = create(:client)
    expect {
      post cars_path, params: { car: { brand: "Honda", model: "Civic", plate: "22-BB-22", client_id: client.id } }
    }.to change(Car, :count).by(1)
    expect(response).to redirect_to(car_path(Car.last))
  end

  it "rejects a car without a plate" do
    client = create(:client)
    expect {
      post cars_path, params: { car: { brand: "Honda", model: "Civic", plate: "", client_id: client.id } }
    }.not_to change(Car, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "updates a car" do
    car = create(:car)
    patch car_path(car), params: { car: { model: "Yaris" } }
    expect(car.reload.model).to eq("Yaris")
  end

  it "destroys a car" do
    car = create(:car)
    expect { delete car_path(car) }.to change(Car, :count).by(-1)
  end

  it "finds cars by partial, case-insensitive plate match" do
    create(:car, plate: "AA-11-BB")
    create(:car, plate: "cc-22-dd")
    get search_cars_path, params: { q: "aa-11" }
    expect(response.body).to include("AA-11-BB")
    expect(response.body).not_to include("CC-22-DD")
  end

  it "shows every match when the query matches more than one plate" do
    create(:car, plate: "AA-11-BB")
    create(:car, plate: "AA-12-BB")
    get search_cars_path, params: { q: "AA-1" }
    expect(response.body).to include("AA-11-BB")
    expect(response.body).to include("AA-12-BB")
  end

  it "shows an empty state when nothing matches" do
    get search_cars_path, params: { q: "ZZ-99" }
    expect(response.body).to include(I18n.t("cars.search.no_results"))
  end

  it "shows a prompt instead of searching with fewer than 2 characters" do
    create(:car, plate: "AA-11-BB")
    get search_cars_path, params: { q: "A" }
    expect(response.body).to include(I18n.t("cars.search.prompt"))
    expect(response.body).not_to include("AA-11-BB")
  end

  it "shows a prompt when the search page is visited directly with no query" do
    get search_cars_path
    expect(response.body).to include(I18n.t("cars.search.prompt"))
  end
end
