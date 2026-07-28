require "rails_helper"

RSpec.describe "Repairs", type: :request do
  before { sign_in create(:user) }

  it "lists repairs" do
    car = create(:car, plate: "44-DD-44")
    create(:repair, car: car)
    get repairs_path
    expect(response.body).to include("44-DD-44")
  end

  it "creates a repair with parts and computes the total" do
    car = create(:car)
    expect {
      post repairs_path, params: {
        repair: {
          date: Date.current, km: 1000, notes: "", car_id: car.id,
          parts_attributes: {
            "0" => { name: "Oil filter", quantity: 1, price: 10 },
            "1" => { name: "Brake pad", quantity: 2, price: 25 }
          }
        }
      }
    }.to change(Repair, :count).by(1).and change(Part, :count).by(2)

    expect(Repair.last.total).to eq(60)
    expect(response).to redirect_to(repair_path(Repair.last))
  end

  it "rejects a repair without km" do
    car = create(:car)
    expect {
      post repairs_path, params: { repair: { date: Date.current, km: "", car_id: car.id } }
    }.not_to change(Repair, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "removes a part and recalculates the total on update" do
    repair = create(:repair)
    part = repair.parts.create!(name: "Oil filter", quantity: 1, price: 10)
    repair.parts.create!(name: "Brake pad", quantity: 2, price: 25)
    repair.save!

    patch repair_path(repair), params: {
      repair: { parts_attributes: { "0" => { id: part.id, _destroy: true } } }
    }

    expect(repair.reload.total).to eq(50)
  end

  it "destroys a repair" do
    repair = create(:repair)
    expect { delete repair_path(repair) }.to change(Repair, :count).by(-1)
  end
end
