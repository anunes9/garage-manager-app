FactoryBot.define do
  factory :car do
    brand { "Toyota" }
    model { "Corolla" }
    sequence(:plate) { |n| "AA-#{100 + n}-BB" }
    sequence(:vin) { |n| "VIN#{1000 + n}" }
    motor { "1.6 Diesel" }
    year { 2020 }
    month { 6 }
    client
  end
end
