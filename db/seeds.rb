# Development-only seed data.
#
# This creates a well-known admin credential, so it must never run outside
# development (e.g. via `rails db:setup` / `rails db:seed` on a deployed app).
if Rails.env.development?
  User.find_or_create_by!(email: "admin@example.com") do |user|
    user.password = "password123"
    user.role = :admin
  end

  User.find_or_create_by!(email: "manager@example.com") do |user|
    user.password = "password123"
    user.role = :garage_manager
  end

  clients = [
    { name: "Ana Silva", phone: "912345671" },
    { name: "Bruno Costa", phone: "912345672" },
    { name: "Carla Mendes", phone: "912345673" },
    { name: "Diogo Ferreira", phone: "912345674" },
    { name: "Elena Rocha", phone: "912345675" }
  ].map do |attrs|
    Client.find_or_create_by!(phone: attrs[:phone]) { |client| client.name = attrs[:name] }
  end

  cars = [
    { plate: "AA-11-BB", brand: "Toyota", model: "Corolla" },
    { plate: "CC-22-DD", brand: "Renault", model: "Clio" },
    { plate: "EE-33-FF", brand: "Peugeot", model: "208" },
    { plate: "GG-44-HH", brand: "Fiat", model: "Panda" },
    { plate: "II-55-JJ", brand: "Volkswagen", model: "Golf" },
    { plate: "KK-66-LL", brand: "BMW", model: "Serie 3" },
    { plate: "MM-77-NN", brand: "Opel", model: "Corsa" }
  ].each_with_index.map do |attrs, index|
    Car.find_or_create_by!(plate: attrs[:plate]) do |car|
      car.brand = attrs[:brand]
      car.model = attrs[:model]
      car.client = clients[index % clients.length]
    end
  end

  repair_templates = [
    { months_ago: 8, km: 12_000, notes: "Mudança de óleo e filtro",
      parts: [ { name: "Óleo motor", quantity: 5, price: 8.50 }, { name: "Filtro de óleo", quantity: 1, price: 12.00 } ] },
    { months_ago: 5, km: 20_000, notes: "Substituição das pastilhas de travão",
      parts: [ { name: "Pastilhas de travão", quantity: 4, price: 18.00 } ] },
    { months_ago: 3, km: 28_000, notes: "Mudança de pneus",
      parts: [ { name: "Pneu", quantity: 4, price: 65.00 } ] },
    { months_ago: 1, km: 35_000, notes: "Revisão geral",
      parts: [ { name: "Filtro de ar", quantity: 1, price: 15.00 }, { name: "Bateria", quantity: 1, price: 90.00 } ] }
  ]

  cars.each_with_index do |car, index|
    repair_templates.values_at(index % 4, (index + 2) % 4).uniq.each do |template|
      repair = Repair.find_or_create_by!(car: car, date: template[:months_ago].months.ago.to_date, km: template[:km]) do |r|
        r.notes = template[:notes]
      end

      next if repair.parts.any?

      template[:parts].each { |part_attrs| repair.parts.create!(part_attrs) }
      repair.save!
    end
  end

  puts "Seeded #{User.count} users, #{Client.count} clients, #{Car.count} cars, #{Repair.count} repairs."
else
  puts "Skipping db/seeds.rb: development-only seed data (current environment: #{Rails.env})."
end
