FactoryBot.define do
  factory :car do
    brand { "Toyota" }
    model { "Corolla" }
    sequence(:plate) { |n| "AA-#{100 + n}-BB" }
    client
  end
end
