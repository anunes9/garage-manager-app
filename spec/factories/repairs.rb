FactoryBot.define do
  factory :repair do
    date { Date.current }
    km { 50_000 }
    notes { "" }
    car
  end
end
