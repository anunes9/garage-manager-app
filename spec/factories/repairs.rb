FactoryBot.define do
  factory :repair do
    date { Date.current }
    km { 50_000 }
    total { 100.00 }
    notes { "" }
    car
  end
end
