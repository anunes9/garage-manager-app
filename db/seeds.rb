# Development-only seed data.
#
# This creates a well-known admin credential, so it must never run outside
# development (e.g. via `rails db:setup` / `rails db:seed` on a deployed app).
if Rails.env.development?
  User.find_or_create_by!(email: "admin@example.com") do |user|
    user.password = "password123"
    user.role = :admin
  end
else
  puts "Skipping db/seeds.rb: development-only seed data (current environment: #{Rails.env})."
end
