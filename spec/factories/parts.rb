FactoryBot.define do
  factory :part do
    name { "Brake pad" }
    quantity { 2 }
    price { 25.50 }
    repair
  end
end
