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
end
