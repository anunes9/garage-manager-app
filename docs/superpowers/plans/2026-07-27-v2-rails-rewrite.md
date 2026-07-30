# Garage Manager v2 Rails Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Garage Manager as a Rails 8 app with Devise-authenticated Admin/GarageManager users, an ActiveAdmin backend for user management, and a Hotwire (Turbo + Stimulus) main app for Client/Car/Repair CRUD.

**Architecture:** A single Rails 8 monolith. Devise backs one `User` model with a `role` enum (`admin`/`garage_manager`). ActiveAdmin mounts at `/admin`, restricted to `admin`-role users, and manages only the `User` resource. The main Hotwire app (mounted at `/`) is where both roles do all Client/Car/Repair/Part CRUD against one shared, non-scoped data pool.

**Tech Stack:** Rails 8, PostgreSQL, Devise, ActiveAdmin, Turbo + Stimulus (importmap), Tailwind CSS, RSpec, FactoryBot, Capybara + Selenium (headless Chrome).

## Global Constraints

- Rails 8, PostgreSQL, RSpec (not Minitest) — per `docs/v2-design.md` §2.
- No data migration from the v1 Appwrite backend — fresh database (§2).
- Devise only; no public sign-up (`:registerable` excluded) and no mailer-dependent modules (`:recoverable`, `:confirmable` excluded) — accounts are created by an Admin with a directly-set password (§3, §5).
- ActiveAdmin manages **only** the `User` resource — never Clients/Cars/Repairs/Parts (§6).
- No authorization gem (Pundit/CanCanCan) — role checks are plain `role` enum + `before_action` guards (§4).
- No per-user data scoping — Admin and GarageManager share one pool of Clients/Cars/Repairs (§4, §7).
- English and Portuguese locales required for all user-facing text (§8).
- `Repair` (not `Budget`) is the resource name throughout code, routes, and views (§3).

---

### Task 1: Bootstrap the Rails app

**Files:**
- Create: entire Rails app skeleton in the repo root (via `rails new .`)
- Modify: `Gemfile`
- Modify: `spec/rails_helper.rb`

**Interfaces:**
- Produces: a working `bin/rails` app with PostgreSQL configured, Tailwind asset pipeline wired into the default layout, and `bundle exec rspec` runnable (0 examples, 0 failures).

- [ ] **Step 1: Generate the Rails app in place**

Run:
```bash
rails new . --database=postgresql --css=tailwind --skip-test --skip-git
```
When prompted about existing files (e.g. `.gitignore`), keep the existing ones (answer `n` to overwrite) since `docs/` and repo metadata must survive.

- [ ] **Step 2: Create the development/test databases**

Run: `bin/rails db:create`
Expected: `Created database 'garage_manager_app_development'` and `..._test` (or equivalent, based on the app name Rails inferred from the directory).

- [ ] **Step 3: Add auth, admin, and test gems to the Gemfile**

Add to `Gemfile`:
```ruby
gem "devise"
gem "activeadmin"

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
```

- [ ] **Step 4: Install gems**

Run: `bundle install`
Expected: exits 0.

- [ ] **Step 5: Install RSpec**

Run: `bin/rails generate rspec:install`
Expected: creates `.rspec`, `spec/spec_helper.rb`, `spec/rails_helper.rb`.

- [ ] **Step 6: Configure `rails_helper.rb` for FactoryBot, Devise test helpers, and system specs**

Edit `spec/rails_helper.rb`, inside the existing `RSpec.configure do |config| ... end` block, add:
```ruby
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome
  end
```
Also add near the top of the file, after the existing `require` lines:
```ruby
require "capybara/rspec"
```

- [ ] **Step 7: Verify the empty suite runs clean**

Run: `bundle exec rspec`
Expected: `0 examples, 0 failures`

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "Bootstrap Rails 8 app with Postgres, Tailwind, RSpec"
```

---

### Task 2: User model with Devise and role enum

**Files:**
- Create: `db/migrate/*_devise_create_users.rb` (generated)
- Create: `db/migrate/*_add_role_to_users.rb` (generated)
- Modify: `app/models/user.rb`
- Modify: `config/initializers/devise.rb` (generated, default config is fine, no edits needed)
- Create: `spec/models/user_spec.rb`
- Create: `spec/factories/users.rb`

**Interfaces:**
- Produces: `User` model with `email`, `password`, `role` enum (`admin: 0`, `garage_manager: 1`), `user.admin?`, `user.garage_manager?`. `current_user` and `authenticate_user!` available in all controllers via Devise.
- Consumes: nothing (first model).

- [ ] **Step 1: Install Devise**

Run: `bin/rails generate devise:install`
Expected output includes setup instructions (safe to ignore — mailer setup is intentionally skipped per Global Constraints).

- [ ] **Step 2: Generate the Devise User model**

Run: `bin/rails generate devise User`
Expected: creates `app/models/user.rb`, `db/migrate/*_devise_create_users.rb`, adds `devise_for :users` to `config/routes.rb`.

- [ ] **Step 3: Add the role column**

Run: `bin/rails generate migration AddRoleToUsers role:integer`

Edit the generated migration file to set a default and `null: false`:
```ruby
class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer, default: 1, null: false
  end
end
```

- [ ] **Step 4: Run migrations**

Run: `bin/rails db:migrate`
Expected: both migrations apply cleanly.

- [ ] **Step 5: Trim Devise modules and add the role enum**

Edit `app/models/user.rb`:
```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  enum :role, { admin: 0, garage_manager: 1 }

  validates :role, presence: true
end
```
(Removes `:registerable`, `:recoverable`, `:trackable`, `:confirmable` from the generator default — no public sign-up, no mailer, per Global Constraints.)

- [ ] **Step 6: Write the factory**

Create `spec/factories/users.rb`:
```ruby
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { :garage_manager }

    trait :admin do
      role { :admin }
    end
  end
end
```

- [ ] **Step 7: Write the model spec**

Replace the generated `spec/models/user_spec.rb` with:
```ruby
require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with an email, password, and role" do
    user = build(:user)
    expect(user).to be_valid
  end

  it "defaults to the garage_manager role" do
    user = User.new
    expect(user.role).to eq("garage_manager")
  end

  it "is invalid without an email" do
    user = build(:user, email: nil)
    expect(user).not_to be_valid
  end

  describe "#admin?" do
    it "is true for admin-role users" do
      expect(build(:user, :admin).admin?).to be true
    end

    it "is false for garage_manager-role users" do
      expect(build(:user).admin?).to be false
    end
  end
end
```

- [ ] **Step 8: Run the spec**

Run: `bundle exec rspec spec/models/user_spec.rb`
Expected: `4 examples, 0 failures`

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "Add Devise-backed User model with admin/garage_manager role"
```

---

### Task 3: ActiveAdmin, restricted to admin role, managing only Users

**Files:**
- Create: `config/initializers/active_admin.rb` (generated, then edited)
- Modify: `app/controllers/application_controller.rb`
- Create: `app/admin/users.rb`
- Modify: `config/routes.rb` (generated)
- Create: `spec/requests/admin_access_spec.rb`

**Interfaces:**
- Consumes: `User#admin?`, `current_user`, `authenticate_user!` (Task 2).
- Produces: `authenticate_admin_user!` (controller method, usable by any future ActiveAdmin-only code); `/admin` routes.

- [ ] **Step 1: Install ActiveAdmin without its own user model**

Run: `bin/rails generate active_admin:install --skip-users`
Expected: creates `config/initializers/active_admin.rb`, `app/admin/dashboard.rb`, adds `ActiveAdmin.routes(self)` to `config/routes.rb`, and a migration for ActiveAdmin's comments feature.

- [ ] **Step 2: Run the ActiveAdmin migration**

Run: `bin/rails db:migrate`

- [ ] **Step 3: Point ActiveAdmin at the existing User model**

Edit `config/initializers/active_admin.rb`, set (uncomment/update existing lines):
```ruby
config.authentication_method = :authenticate_admin_user!
config.current_user_method = :current_user
config.logout_link_path = :destroy_user_session_path
```

- [ ] **Step 4: Add the admin-only guard to ApplicationController**

Edit `app/controllers/application_controller.rb`:
```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def after_sign_in_path_for(resource)
    clients_path
  end

  def authenticate_admin_user!
    authenticate_user!
    redirect_to root_path, alert: "Not authorized" unless current_user.admin?
  end
end
```
(`clients_path` will exist once Task 8 adds the route — this reference is safe to add now since it's only invoked at runtime, not load time.)

- [ ] **Step 5: Register the User resource in ActiveAdmin**

Create `app/admin/users.rb`:
```ruby
ActiveAdmin.register User do
  permit_params :email, :password, :password_confirmation, :role

  index do
    selectable_column
    id_column
    column :email
    column :role
    column :created_at
    actions
  end

  filter :email
  filter :role, as: :select, collection: User.roles.keys

  form do |f|
    f.inputs do
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :role, as: :select, collection: User.roles.keys, include_blank: false
    end
    f.actions
  end
end
```

- [ ] **Step 6: Write the access-control request spec**

Create `spec/requests/admin_access_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe "ActiveAdmin access", type: :request do
  it "denies a garage_manager" do
    sign_in create(:user)
    get "/admin/users"
    expect(response).to redirect_to(root_path)
  end

  it "denies a signed-out visitor" do
    get "/admin/users"
    expect(response).to redirect_to(new_user_session_path)
  end

  it "allows an admin" do
    sign_in create(:user, :admin)
    get "/admin/users"
    expect(response).to have_http_status(:ok)
  end
end
```

- [ ] **Step 7: Run the spec**

Run: `bundle exec rspec spec/requests/admin_access_spec.rb`
Expected: `3 examples, 0 failures`

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "Add ActiveAdmin restricted to admin role, managing Users only"
```

---

### Task 4: Client model

**Files:**
- Create: `db/migrate/*_create_clients.rb` (generated)
- Modify: `app/models/client.rb` (generated stub, then edited)
- Create: `spec/models/client_spec.rb`
- Create: `spec/factories/clients.rb`

**Interfaces:**
- Produces: `Client` with `name`, `phone`, `has_many :cars`.
- Consumes: nothing new.

- [ ] **Step 1: Generate the model**

Run: `bin/rails generate model Client name:string phone:string`

- [ ] **Step 2: Migrate**

Run: `bin/rails db:migrate`

- [ ] **Step 3: Add validations and association**

Edit `app/models/client.rb`:
```ruby
class Client < ApplicationRecord
  has_many :cars, dependent: :destroy

  validates :name, presence: true
  validates :phone, presence: true, length: { is: 9 }
end
```

- [ ] **Step 4: Write the factory**

Create `spec/factories/clients.rb`:
```ruby
FactoryBot.define do
  factory :client do
    name { "Jane Doe" }
    phone { "912345678" }
  end
end
```

- [ ] **Step 5: Write the model spec**

Create `spec/models/client_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe Client, type: :model do
  it "is valid with a name and 9-digit phone" do
    expect(build(:client)).to be_valid
  end

  it "is invalid without a name" do
    expect(build(:client, name: nil)).not_to be_valid
  end

  it "is invalid with a phone that isn't 9 characters" do
    expect(build(:client, phone: "123")).not_to be_valid
  end

  it "destroys its cars when destroyed" do
    client = create(:client)
    car = create(:car, client: client)
    expect { client.destroy }.to change(Car, :count).by(-1)
    expect { car.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
```
(The last example references the `:car` factory built in Task 5 — this spec file is not run until Task 5 lands, so that's fine at write time, but do not run it yet.)

- [ ] **Step 6: Run the spec, expecting the last example to error on missing factory**

Run: `bundle exec rspec spec/models/client_spec.rb`
Expected: 3 passing, 1 erroring with "Factory not registered: car" — this is expected until Task 5. Confirm the first 3 pass before moving on.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Add Client model"
```

---

### Task 5: Car model

**Files:**
- Create: `db/migrate/*_create_cars.rb` (generated)
- Modify: `app/models/car.rb` (generated stub, then edited)
- Create: `spec/models/car_spec.rb`
- Create: `spec/factories/cars.rb`

**Interfaces:**
- Consumes: `Client` (Task 4).
- Produces: `Car` with `brand`, `model`, `plate`, `belongs_to :client`, `has_many :repairs`.

- [ ] **Step 1: Generate the model**

Run: `bin/rails generate model Car brand:string model:string plate:string client:references`

- [ ] **Step 2: Migrate**

Run: `bin/rails db:migrate`

- [ ] **Step 3: Add validations and association**

Edit `app/models/car.rb`:
```ruby
class Car < ApplicationRecord
  belongs_to :client
  has_many :repairs, dependent: :destroy

  validates :brand, presence: true
  validates :model, presence: true
  validates :plate, presence: true, uniqueness: true
end
```

- [ ] **Step 4: Write the factory**

Create `spec/factories/cars.rb`:
```ruby
FactoryBot.define do
  factory :car do
    brand { "Toyota" }
    model { "Corolla" }
    sequence(:plate) { |n| "AA-#{100 + n}-BB" }
    client
  end
end
```

- [ ] **Step 5: Write the model spec**

Create `spec/models/car_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe Car, type: :model do
  it "is valid with brand, model, plate, and a client" do
    expect(build(:car)).to be_valid
  end

  it "is invalid without a plate" do
    expect(build(:car, plate: nil)).not_to be_valid
  end

  it "is invalid with a duplicate plate" do
    create(:car, plate: "AA-11-BB")
    expect(build(:car, plate: "AA-11-BB")).not_to be_valid
  end

  it "is invalid without a client" do
    expect(build(:car, client: nil)).not_to be_valid
  end
end
```

- [ ] **Step 6: Run both Car and Client specs**

Run: `bundle exec rspec spec/models/car_spec.rb spec/models/client_spec.rb`
Expected: `8 examples, 0 failures` (4 from Car, 4 from Client — Client's last example now resolves since `:car` factory exists).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Add Car model"
```

---

### Task 6: Repair and Part models, with nested attributes and total calculation

**Files:**
- Create: `db/migrate/*_create_repairs.rb` (generated)
- Create: `db/migrate/*_create_parts.rb` (generated)
- Modify: `app/models/repair.rb` (generated stub, then edited)
- Modify: `app/models/part.rb` (generated stub, then edited)
- Create: `spec/models/repair_spec.rb`
- Create: `spec/models/part_spec.rb`
- Create: `spec/factories/repairs.rb`
- Create: `spec/factories/parts.rb`

**Interfaces:**
- Consumes: `Car` (Task 5).
- Produces: `Repair` with `date`, `km`, `total` (auto-calculated), `notes`, `belongs_to :car`, `has_many :parts`, `accepts_nested_attributes_for :parts`. `Part` with `name`, `quantity`, `price`, `belongs_to :repair`. `repair.parts_attributes=` usable by the RepairsController in Task 10.

- [ ] **Step 1: Generate the Repair model**

Run: `bin/rails generate model Repair date:date km:integer total:decimal{10.2} notes:text car:references`

- [ ] **Step 2: Generate the Part model**

Run: `bin/rails generate model Part name:string quantity:integer price:decimal{10.2} repair:references`

- [ ] **Step 3: Migrate**

Run: `bin/rails db:migrate`

- [ ] **Step 4: Add validations, association, and total calculation to Repair**

Edit `app/models/repair.rb`:
```ruby
class Repair < ApplicationRecord
  belongs_to :car
  has_many :parts, dependent: :destroy
  accepts_nested_attributes_for :parts, allow_destroy: true, reject_if: :all_blank

  validates :date, presence: true
  validates :km, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total

  private

  def calculate_total
    self.total = parts.reject(&:marked_for_destruction?)
                       .sum { |part| part.price.to_f * part.quantity.to_i }
  end
end
```

- [ ] **Step 5: Add validations and association to Part**

Edit `app/models/part.rb`:
```ruby
class Part < ApplicationRecord
  belongs_to :repair

  validates :name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
```

- [ ] **Step 6: Write factories**

Create `spec/factories/parts.rb`:
```ruby
FactoryBot.define do
  factory :part do
    name { "Brake pad" }
    quantity { 2 }
    price { 25.50 }
    repair
  end
end
```

Create `spec/factories/repairs.rb`:
```ruby
FactoryBot.define do
  factory :repair do
    date { Date.current }
    km { 50_000 }
    notes { "" }
    car
  end
end
```

- [ ] **Step 7: Write the Part model spec**

Create `spec/models/part_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe Part, type: :model do
  it "is valid with a name, quantity, price, and repair" do
    expect(build(:part)).to be_valid
  end

  it "is invalid with a zero quantity" do
    expect(build(:part, quantity: 0)).not_to be_valid
  end

  it "is invalid with a negative price" do
    expect(build(:part, price: -1)).not_to be_valid
  end
end
```

- [ ] **Step 8: Write the Repair model spec**

Create `spec/models/repair_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe Repair, type: :model do
  it "is valid with a date, km, and a car" do
    expect(build(:repair)).to be_valid
  end

  it "is invalid without km" do
    expect(build(:repair, km: nil)).not_to be_valid
  end

  it "calculates total as the sum of price * quantity across its parts" do
    repair = create(:repair)
    repair.parts.create!(name: "Oil filter", quantity: 1, price: 10)
    repair.parts.create!(name: "Brake pad", quantity: 2, price: 25)
    repair.save!
    expect(repair.reload.total).to eq(60)
  end

  it "excludes parts marked for destruction from the total" do
    repair = create(:repair)
    part = repair.parts.create!(name: "Oil filter", quantity: 1, price: 10)
    repair.parts.create!(name: "Brake pad", quantity: 2, price: 25)
    repair.update!(parts_attributes: [{ id: part.id, _destroy: true }])
    expect(repair.reload.total).to eq(50)
  end
end
```

- [ ] **Step 9: Run the specs**

Run: `bundle exec rspec spec/models/repair_spec.rb spec/models/part_spec.rb`
Expected: `7 examples, 0 failures`

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Add Repair and Part models with nested attributes and total calculation"
```

---

### Task 7: Application layout, navigation, and routes

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Modify: `config/routes.rb`

**Interfaces:**
- Consumes: `current_user`, `current_user.admin?` (Task 2), `authenticate_user!` (already global via `ApplicationController`, Task 3).
- Produces: `root_path` → Clients index; nav bar present on every page; `clients_path`, `cars_path`, `repairs_path` route helpers (routes only — controllers land in Tasks 8–10).

- [ ] **Step 1: Add resourceful routes and root**

Edit `config/routes.rb`, inside the `Rails.application.routes.draw do ... end` block (alongside the existing `devise_for :users` and `ActiveAdmin.routes(self)` lines already added by earlier generators):
```ruby
  resources :clients
  resources :cars
  resources :repairs

  root "clients#index"
```

- [ ] **Step 2: Add the nav bar to the layout**

Edit `app/views/layouts/application.html.erb`, inside `<body>`, before `<%= yield %>`:
```erb
<% if user_signed_in? %>
  <nav class="bg-gray-800 text-white px-4 py-3 flex items-center gap-4">
    <%= link_to "Clients", clients_path, class: "hover:underline" %>
    <%= link_to "Cars", cars_path, class: "hover:underline" %>
    <%= link_to "Repairs", repairs_path, class: "hover:underline" %>
    <% if current_user.admin? %>
      <%= link_to "Admin", "/admin", class: "hover:underline" %>
    <% end %>
    <span class="ml-auto text-sm"><%= current_user.email %></span>
    <%= button_to "Sign out", destroy_user_session_path, method: :delete, class: "hover:underline bg-transparent border-0 p-0 text-sm cursor-pointer" %>
  </nav>
<% end %>

<main class="max-w-4xl mx-auto p-6">
  <% if notice %>
    <p class="mb-4 text-green-700"><%= notice %></p>
  <% end %>
  <% if alert %>
    <p class="mb-4 text-red-700"><%= alert %></p>
  <% end %>
```

Note: the file's existing `<%= yield %>` stays where it is, now inside the new `<main>` opened above — close it with `</main>` immediately after the existing `<%= yield %>` line.

- [ ] **Step 3: Verify routes load without a controller error (expected controller-missing error confirms routing is wired)**

Run: `bin/rails routes | grep -E "clients|cars|repairs|root"`
Expected: five resourceful routes each for clients/cars/repairs, plus `root GET / clients#index`.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "Add navigation layout and Client/Car/Repair routes"
```

---

### Task 8: Clients CRUD

**Files:**
- Create: `app/controllers/clients_controller.rb`
- Create: `app/views/clients/index.html.erb`
- Create: `app/views/clients/show.html.erb`
- Create: `app/views/clients/new.html.erb`
- Create: `app/views/clients/edit.html.erb`
- Create: `app/views/clients/_form.html.erb`
- Create: `spec/requests/clients_spec.rb`
- Create: `spec/system/clients_spec.rb`

**Interfaces:**
- Consumes: `Client` (Task 4), nav/layout (Task 7), `sign_in` test helper (Task 1/2).
- Produces: `/clients` CRUD, reused as the pattern for Cars (Task 9) and Repairs (Task 10).

- [ ] **Step 1: Write the request spec**

Create `spec/requests/clients_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe "Clients", type: :request do
  before { sign_in create(:user) }

  it "lists clients" do
    client = create(:client, name: "Alice")
    get clients_path
    expect(response.body).to include("Alice")
  end

  it "creates a client" do
    expect {
      post clients_path, params: { client: { name: "Bob", phone: "912345678" } }
    }.to change(Client, :count).by(1)
    expect(response).to redirect_to(client_path(Client.last))
  end

  it "rejects an invalid client" do
    expect {
      post clients_path, params: { client: { name: "", phone: "" } }
    }.not_to change(Client, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "updates a client" do
    client = create(:client)
    patch client_path(client), params: { client: { name: "Updated Name" } }
    expect(client.reload.name).to eq("Updated Name")
  end

  it "destroys a client" do
    client = create(:client)
    expect { delete client_path(client) }.to change(Client, :count).by(-1)
  end
end
```

- [ ] **Step 2: Run it to confirm it fails on the missing controller**

Run: `bundle exec rspec spec/requests/clients_spec.rb`
Expected: FAIL — `uninitialized constant ClientsController` (routes already exist from Task 7).

- [ ] **Step 3: Write the controller**

Create `app/controllers/clients_controller.rb`:
```ruby
class ClientsController < ApplicationController
  before_action :set_client, only: %i[show edit update destroy]

  def index
    @clients = Client.order(:name)
  end

  def show
  end

  def new
    @client = Client.new
  end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to @client, notice: "Client created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: "Client updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, notice: "Client removed."
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :phone)
  end
end
```

- [ ] **Step 4: Write the views**

Create `app/views/clients/_form.html.erb`:
```erb
<%= form_with model: client, class: "space-y-4" do |f| %>
  <% if client.errors.any? %>
    <div class="text-red-700">
      <ul>
        <% client.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :name, class: "block font-medium" %>
    <%= f.text_field :name, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <div>
    <%= f.label :phone, class: "block font-medium" %>
    <%= f.text_field :phone, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <%= f.submit class: "bg-blue-600 text-white px-4 py-2 rounded cursor-pointer" %>
<% end %>
```

Create `app/views/clients/index.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">Clients</h1>

<%= link_to "New Client", new_client_path, class: "bg-blue-600 text-white px-4 py-2 rounded" %>

<table class="w-full mt-4 border-collapse">
  <thead>
    <tr class="text-left border-b">
      <th class="py-2">Name</th>
      <th class="py-2">Phone</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <% @clients.each do |client| %>
      <tr class="border-b">
        <td class="py-2"><%= link_to client.name, client_path(client) %></td>
        <td class="py-2"><%= client.phone %></td>
        <td class="py-2 text-right">
          <%= link_to "Edit", edit_client_path(client) %>
          <%= button_to "Delete", client_path(client), method: :delete, class: "bg-transparent border-0 p-0 text-red-700 underline cursor-pointer ml-2", form: { data: { turbo_confirm: "Are you sure?" } } %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

Create `app/views/clients/show.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4"><%= @client.name %></h1>

<p><strong>Phone:</strong> <%= @client.phone %></p>

<h2 class="text-xl font-semibold mt-6 mb-2">Cars</h2>
<ul class="list-disc list-inside">
  <% @client.cars.each do |car| %>
    <li><%= link_to "#{car.brand} #{car.model} (#{car.plate})", car_path(car) %></li>
  <% end %>
</ul>

<%= link_to "Edit", edit_client_path(@client), class: "inline-block mt-4 underline" %>
<%= link_to "Back", clients_path, class: "inline-block mt-4 ml-4 underline" %>
```

Create `app/views/clients/new.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">New Client</h1>
<%= render "form", client: @client %>
```

Create `app/views/clients/edit.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">Edit Client</h1>
<%= render "form", client: @client %>
```

- [ ] **Step 5: Run the request spec**

Run: `bundle exec rspec spec/requests/clients_spec.rb`
Expected: `5 examples, 0 failures`

- [ ] **Step 6: Write and run the system spec**

Create `spec/system/clients_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe "Managing clients", type: :system do
  before { sign_in create(:user) }

  it "creates a client" do
    visit new_client_path

    fill_in "Name", with: "Carol"
    fill_in "Phone", with: "912345678"
    click_on "Create Client"

    expect(page).to have_content("Client created")
    expect(page).to have_content("Carol")
  end
end
```

Run: `bundle exec rspec spec/system/clients_spec.rb`
Expected: `1 example, 0 failures`

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Add Clients CRUD"
```

---

### Task 9: Cars CRUD

**Files:**
- Create: `app/controllers/cars_controller.rb`
- Create: `app/views/cars/index.html.erb`
- Create: `app/views/cars/show.html.erb`
- Create: `app/views/cars/new.html.erb`
- Create: `app/views/cars/edit.html.erb`
- Create: `app/views/cars/_form.html.erb`
- Create: `spec/requests/cars_spec.rb`
- Create: `spec/system/cars_spec.rb`

**Interfaces:**
- Consumes: `Car`, `Client` (Tasks 4–5), Clients CRUD pattern (Task 8).
- Produces: `/cars` CRUD.

- [ ] **Step 1: Write the request spec**

Create `spec/requests/cars_spec.rb`:
```ruby
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
```

- [ ] **Step 2: Run it to confirm it fails on the missing controller**

Run: `bundle exec rspec spec/requests/cars_spec.rb`
Expected: FAIL — `uninitialized constant CarsController`.

- [ ] **Step 3: Write the controller**

Create `app/controllers/cars_controller.rb`:
```ruby
class CarsController < ApplicationController
  before_action :set_car, only: %i[show edit update destroy]

  def index
    @cars = Car.includes(:client).order(:plate)
  end

  def show
  end

  def new
    @car = Car.new
  end

  def create
    @car = Car.new(car_params)
    if @car.save
      redirect_to @car, notice: "Car created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @car.update(car_params)
      redirect_to @car, notice: "Car updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @car.destroy
    redirect_to cars_path, notice: "Car removed."
  end

  private

  def set_car
    @car = Car.find(params[:id])
  end

  def car_params
    params.require(:car).permit(:brand, :model, :plate, :client_id)
  end
end
```

- [ ] **Step 4: Write the views**

Create `app/views/cars/_form.html.erb`:
```erb
<%= form_with model: car, class: "space-y-4" do |f| %>
  <% if car.errors.any? %>
    <div class="text-red-700">
      <ul>
        <% car.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :client_id, "Client", class: "block font-medium" %>
    <%= f.collection_select :client_id, Client.order(:name), :id, :name, { prompt: true }, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <div>
    <%= f.label :brand, class: "block font-medium" %>
    <%= f.text_field :brand, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <div>
    <%= f.label :model, class: "block font-medium" %>
    <%= f.text_field :model, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <div>
    <%= f.label :plate, class: "block font-medium" %>
    <%= f.text_field :plate, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <%= f.submit class: "bg-blue-600 text-white px-4 py-2 rounded cursor-pointer" %>
<% end %>
```

Create `app/views/cars/index.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">Cars</h1>

<%= link_to "New Car", new_car_path, class: "bg-blue-600 text-white px-4 py-2 rounded" %>

<table class="w-full mt-4 border-collapse">
  <thead>
    <tr class="text-left border-b">
      <th class="py-2">Plate</th>
      <th class="py-2">Brand / Model</th>
      <th class="py-2">Client</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <% @cars.each do |car| %>
      <tr class="border-b">
        <td class="py-2"><%= link_to car.plate, car_path(car) %></td>
        <td class="py-2"><%= "#{car.brand} #{car.model}" %></td>
        <td class="py-2"><%= link_to car.client.name, client_path(car.client) %></td>
        <td class="py-2 text-right">
          <%= link_to "Edit", edit_car_path(car) %>
          <%= button_to "Delete", car_path(car), method: :delete, class: "bg-transparent border-0 p-0 text-red-700 underline cursor-pointer ml-2", form: { data: { turbo_confirm: "Are you sure?" } } %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

Create `app/views/cars/show.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4"><%= "#{@car.brand} #{@car.model}" %></h1>

<p><strong>Plate:</strong> <%= @car.plate %></p>
<p><strong>Client:</strong> <%= link_to @car.client.name, client_path(@car.client) %></p>

<h2 class="text-xl font-semibold mt-6 mb-2">Repairs</h2>
<ul class="list-disc list-inside">
  <% @car.repairs.order(date: :desc).each do |repair| %>
    <li><%= link_to "#{repair.date} — #{repair.total}€", repair_path(repair) %></li>
  <% end %>
</ul>

<%= link_to "Edit", edit_car_path(@car), class: "inline-block mt-4 underline" %>
<%= link_to "Back", cars_path, class: "inline-block mt-4 ml-4 underline" %>
```

Create `app/views/cars/new.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">New Car</h1>
<%= render "form", car: @car %>
```

Create `app/views/cars/edit.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">Edit Car</h1>
<%= render "form", car: @car %>
```

- [ ] **Step 5: Run the request spec**

Run: `bundle exec rspec spec/requests/cars_spec.rb`
Expected: `5 examples, 0 failures`

- [ ] **Step 6: Write and run the system spec**

Create `spec/system/cars_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe "Managing cars", type: :system do
  before { sign_in create(:user) }

  it "creates a car for an existing client" do
    client = create(:client, name: "Dana")
    visit new_car_path

    select "Dana", from: "Client"
    fill_in "Brand", with: "Ford"
    fill_in "Model", with: "Focus"
    fill_in "Plate", with: "33-CC-33"
    click_on "Create Car"

    expect(page).to have_content("Car created")
    expect(page).to have_content("33-CC-33")
  end
end
```

Run: `bundle exec rspec spec/system/cars_spec.rb`
Expected: `1 example, 0 failures`

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Add Cars CRUD"
```

---

### Task 10: Repairs CRUD with a dynamic Parts form

**Files:**
- Create: `app/controllers/repairs_controller.rb`
- Create: `app/views/repairs/index.html.erb`
- Create: `app/views/repairs/show.html.erb`
- Create: `app/views/repairs/new.html.erb`
- Create: `app/views/repairs/edit.html.erb`
- Create: `app/views/repairs/_form.html.erb`
- Create: `app/views/repairs/_part_fields.html.erb`
- Create: `app/javascript/controllers/nested_form_controller.js`
- Create: `spec/requests/repairs_spec.rb`
- Create: `spec/system/repairs_spec.rb`

**Interfaces:**
- Consumes: `Repair`, `Part`, `Car` (Tasks 5–6), Clients/Cars CRUD pattern (Tasks 8–9).
- Produces: `/repairs` CRUD with nested Part rows added/removed client-side via a `nested-form` Stimulus controller (auto-registered by Rails 8's default `app/javascript/controllers/index.js`, no manual registration step needed).

- [ ] **Step 1: Write the request spec**

Create `spec/requests/repairs_spec.rb`:
```ruby
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
```

- [ ] **Step 2: Run it to confirm it fails on the missing controller**

Run: `bundle exec rspec spec/requests/repairs_spec.rb`
Expected: FAIL — `uninitialized constant RepairsController`.

- [ ] **Step 3: Write the controller**

Create `app/controllers/repairs_controller.rb`:
```ruby
class RepairsController < ApplicationController
  before_action :set_repair, only: %i[show edit update destroy]

  def index
    @repairs = Repair.includes(:car).order(date: :desc)
  end

  def show
  end

  def new
    @repair = Repair.new
    @repair.parts.build
  end

  def create
    @repair = Repair.new(repair_params)
    if @repair.save
      redirect_to @repair, notice: "Repair created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @repair.update(repair_params)
      redirect_to @repair, notice: "Repair updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @repair.destroy
    redirect_to repairs_path, notice: "Repair removed."
  end

  private

  def set_repair
    @repair = Repair.find(params[:id])
  end

  def repair_params
    params.require(:repair).permit(
      :date, :km, :notes, :car_id,
      parts_attributes: %i[id name quantity price _destroy]
    )
  end
end
```

- [ ] **Step 4: Write the Stimulus controller for dynamic Part rows**

Create `app/javascript/controllers/nested_form_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "parts"]

  add(event) {
    event.preventDefault()
    const newId = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, newId)
    this.partsTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest(".part-fields")
    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()
    } else {
      wrapper.querySelector("input[name*='_destroy']").value = "1"
      wrapper.style.display = "none"
    }
  }
}
```

- [ ] **Step 5: Write the Part row partial**

Create `app/views/repairs/_part_fields.html.erb`:
```erb
<div class="part-fields flex gap-2 mb-2 items-start" data-new-record="<%= f.object.new_record? %>">
  <%= f.text_field :name, placeholder: "Name", class: "border rounded px-2 py-1 flex-1" %>
  <%= f.number_field :quantity, placeholder: "Qty", class: "border rounded px-2 py-1 w-20" %>
  <%= f.number_field :price, step: "0.01", placeholder: "Price", class: "border rounded px-2 py-1 w-24" %>
  <%= f.hidden_field :_destroy %>
  <button type="button" data-action="nested-form#remove" class="text-red-700 underline">Remove</button>
</div>
```

- [ ] **Step 6: Write the Repair form with the nested Parts UI**

Create `app/views/repairs/_form.html.erb`:
```erb
<%= form_with model: repair, class: "space-y-4", data: { controller: "nested-form" } do |f| %>
  <% if repair.errors.any? %>
    <div class="text-red-700">
      <ul>
        <% repair.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :car_id, "Car", class: "block font-medium" %>
    <%= f.collection_select :car_id, Car.order(:plate), :id, :plate, { prompt: true }, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <div>
    <%= f.label :date, class: "block font-medium" %>
    <%= f.date_field :date, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <div>
    <%= f.label :km, class: "block font-medium" %>
    <%= f.number_field :km, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <div>
    <%= f.label :notes, class: "block font-medium" %>
    <%= f.text_area :notes, class: "border rounded px-2 py-1 w-full" %>
  </div>

  <div>
    <span class="block font-medium mb-2">Parts</span>

    <div data-nested-form-target="parts">
      <%= f.fields_for :parts do |part_fields| %>
        <%= render "part_fields", f: part_fields %>
      <% end %>
    </div>

    <template data-nested-form-target="template">
      <%= f.fields_for :parts, Part.new, child_index: "NEW_RECORD" do |part_fields| %>
        <%= render "part_fields", f: part_fields %>
      <% end %>
    </template>

    <button type="button" data-action="nested-form#add" class="underline text-blue-700">Add Part</button>
  </div>

  <%= f.submit class: "bg-blue-600 text-white px-4 py-2 rounded cursor-pointer" %>
<% end %>
```

- [ ] **Step 7: Write the remaining views**

Create `app/views/repairs/index.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">Repairs</h1>

<%= link_to "New Repair", new_repair_path, class: "bg-blue-600 text-white px-4 py-2 rounded" %>

<table class="w-full mt-4 border-collapse">
  <thead>
    <tr class="text-left border-b">
      <th class="py-2">Date</th>
      <th class="py-2">Car</th>
      <th class="py-2">Total</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <% @repairs.each do |repair| %>
      <tr class="border-b">
        <td class="py-2"><%= link_to repair.date, repair_path(repair) %></td>
        <td class="py-2"><%= link_to repair.car.plate, car_path(repair.car) %></td>
        <td class="py-2"><%= "#{repair.total}€" %></td>
        <td class="py-2 text-right">
          <%= link_to "Edit", edit_repair_path(repair) %>
          <%= button_to "Delete", repair_path(repair), method: :delete, class: "bg-transparent border-0 p-0 text-red-700 underline cursor-pointer ml-2", form: { data: { turbo_confirm: "Are you sure?" } } %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

Create `app/views/repairs/show.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">Repair on <%= @repair.date %></h1>

<p><strong>Car:</strong> <%= link_to @repair.car.plate, car_path(@repair.car) %></p>
<p><strong>Km:</strong> <%= @repair.km %></p>
<p><strong>Notes:</strong> <%= @repair.notes %></p>

<h2 class="text-xl font-semibold mt-6 mb-2">Parts</h2>
<table class="w-full border-collapse">
  <thead>
    <tr class="text-left border-b">
      <th class="py-2">Name</th>
      <th class="py-2">Quantity</th>
      <th class="py-2">Price</th>
    </tr>
  </thead>
  <tbody>
    <% @repair.parts.each do |part| %>
      <tr class="border-b">
        <td class="py-2"><%= part.name %></td>
        <td class="py-2"><%= part.quantity %></td>
        <td class="py-2"><%= "#{part.price}€" %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<p class="mt-4 font-bold">Total: <%= "#{@repair.total}€" %></p>

<%= link_to "Edit", edit_repair_path(@repair), class: "inline-block mt-4 underline" %>
<%= link_to "Back", repairs_path, class: "inline-block mt-4 ml-4 underline" %>
```

Create `app/views/repairs/new.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">New Repair</h1>
<%= render "form", repair: @repair %>
```

Create `app/views/repairs/edit.html.erb`:
```erb
<h1 class="text-2xl font-bold mb-4">Edit Repair</h1>
<%= render "form", repair: @repair %>
```

- [ ] **Step 8: Run the request spec**

Run: `bundle exec rspec spec/requests/repairs_spec.rb`
Expected: `5 examples, 0 failures`

- [ ] **Step 9: Write and run the system spec**

Create `spec/system/repairs_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe "Managing repairs", type: :system do
  before { sign_in create(:user) }

  it "creates a repair with two dynamically-added parts" do
    car = create(:car, plate: "55-EE-55")
    visit new_repair_path

    select "55-EE-55", from: "Car"
    fill_in "Date", with: Date.current
    fill_in "Km", with: 1000

    click_on "Add Part"
    within all(".part-fields").last do
      fill_in "Name", with: "Oil filter"
      fill_in "Qty", with: 1
      fill_in "Price", with: 10
    end

    click_on "Add Part"
    within all(".part-fields").last do
      fill_in "Name", with: "Brake pad"
      fill_in "Qty", with: 2
      fill_in "Price", with: 25
    end

    click_on "Create Repair"

    expect(page).to have_content("Repair created")
    expect(page).to have_content("60.0€")
  end
end
```

Run: `bundle exec rspec spec/system/repairs_spec.rb`
Expected: `1 example, 0 failures`

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Add Repairs CRUD with dynamic Parts form"
```

---

### Task 11: English and Portuguese locales

**Files:**
- Modify: `config/locales/en.yml`
- Create: `config/locales/pt.yml`
- Modify: `config/application.rb`
- Modify: all Clients/Cars/Repairs views (Tasks 8–10) to use `t(...)` instead of hardcoded strings
- Modify: `app/views/layouts/application.html.erb` (nav labels)
- Create: `spec/requests/locale_spec.rb`

**Interfaces:**
- Consumes: all views from Tasks 7–10.
- Produces: `I18n.available_locales = [:en, :pt]`; `?locale=pt` switches UI language.

- [ ] **Step 1: Configure available locales and locale-from-params**

Edit `config/application.rb`, inside the `class Application < Rails::Application` block:
```ruby
    config.i18n.available_locales = [:en, :pt]
    config.i18n.default_locale = :en
```

Edit `app/controllers/application_controller.rb`, add:
```ruby
  around_action :switch_locale

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    { locale: params[:locale] }
  end
```

- [ ] **Step 2: Write the English locale file**

Edit `config/locales/en.yml`:
```yaml
en:
  nav:
    clients: "Clients"
    cars: "Cars"
    repairs: "Repairs"
    admin: "Admin"
    sign_out: "Sign out"
  clients:
    title: "Clients"
    new: "New Client"
    edit: "Edit Client"
    fields:
      name: "Name"
      phone: "Phone"
    created: "Client created."
    updated: "Client updated."
    destroyed: "Client removed."
  cars:
    title: "Cars"
    new: "New Car"
    edit: "Edit Car"
    fields:
      client: "Client"
      brand: "Brand"
      model: "Model"
      plate: "Plate"
    created: "Car created."
    updated: "Car updated."
    destroyed: "Car removed."
  repairs:
    title: "Repairs"
    new: "New Repair"
    edit: "Edit Repair"
    fields:
      car: "Car"
      date: "Date"
      km: "Km"
      notes: "Notes"
      parts: "Parts"
      total: "Total"
    add_part: "Add Part"
    remove_part: "Remove"
    created: "Repair created."
    updated: "Repair updated."
    destroyed: "Repair removed."
  parts:
    fields:
      name: "Name"
      quantity: "Quantity"
      price: "Price"
  common:
    back: "Back"
    edit: "Edit"
    delete: "Delete"
    confirm: "Are you sure?"
```

- [ ] **Step 3: Write the Portuguese locale file**

Create `config/locales/pt.yml`:
```yaml
pt:
  nav:
    clients: "Clientes"
    cars: "Carros"
    repairs: "Reparações"
    admin: "Admin"
    sign_out: "Sair"
  clients:
    title: "Clientes"
    new: "Novo Cliente"
    edit: "Editar Cliente"
    fields:
      name: "Nome"
      phone: "Telefone"
    created: "Cliente criado."
    updated: "Cliente atualizado."
    destroyed: "Cliente removido."
  cars:
    title: "Carros"
    new: "Novo Carro"
    edit: "Editar Carro"
    fields:
      client: "Cliente"
      brand: "Marca"
      model: "Modelo"
      plate: "Matrícula"
    created: "Carro criado."
    updated: "Carro atualizado."
    destroyed: "Carro removido."
  repairs:
    title: "Reparações"
    new: "Nova Reparação"
    edit: "Editar Reparação"
    fields:
      car: "Carro"
      date: "Data"
      km: "Km"
      notes: "Notas"
      parts: "Peças"
      total: "Total"
    add_part: "Adicionar Peça"
    remove_part: "Remover"
    created: "Reparação criada."
    updated: "Reparação atualizada."
    destroyed: "Reparação removida."
  parts:
    fields:
      name: "Nome"
      quantity: "Quantidade"
      price: "Preço"
  common:
    back: "Voltar"
    edit: "Editar"
    delete: "Eliminar"
    confirm: "Tem a certeza?"
```

- [ ] **Step 4: Replace hardcoded strings with `t(...)` in the layout**

Edit `app/views/layouts/application.html.erb`, replace the nav `link_to` labels and sign-out button text:
```erb
    <%= link_to t("nav.clients"), clients_path, class: "hover:underline" %>
    <%= link_to t("nav.cars"), cars_path, class: "hover:underline" %>
    <%= link_to t("nav.repairs"), repairs_path, class: "hover:underline" %>
    <% if current_user.admin? %>
      <%= link_to t("nav.admin"), "/admin", class: "hover:underline" %>
    <% end %>
    <span class="ml-auto text-sm"><%= current_user.email %></span>
    <%= button_to t("nav.sign_out"), destroy_user_session_path, method: :delete, class: "hover:underline bg-transparent border-0 p-0 text-sm cursor-pointer" %>
```

- [ ] **Step 5: Replace hardcoded strings in Clients views and controller flash messages**

Edit `app/controllers/clients_controller.rb`: replace `"Client created."` → `t("clients.created")`, `"Client updated."` → `t("clients.updated")`, `"Client removed."` → `t("clients.destroyed")`.

Edit `app/views/clients/index.html.erb`, `show.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb`: replace hardcoded headings/labels/buttons with `t("clients.title")`, `t("clients.new")`, `t("clients.edit")`, `t("clients.fields.name")`, `t("clients.fields.phone")`, `t("common.back")`, `t("common.edit")`, `t("common.delete")`, and set `data: { turbo_confirm: t("common.confirm") }`.

- [ ] **Step 6: Replace hardcoded strings in Cars views and controller flash messages**

Same pattern as Step 5, using `cars.*` keys, applied to `app/controllers/cars_controller.rb` and `app/views/cars/*.html.erb`.

- [ ] **Step 7: Replace hardcoded strings in Repairs views and controller flash messages**

Same pattern, using `repairs.*` and `parts.fields.*` keys, applied to `app/controllers/repairs_controller.rb`, `app/views/repairs/*.html.erb`, and the "Add Part" / "Remove" buttons in `_form.html.erb` / `_part_fields.html.erb` (`t("repairs.add_part")`, `t("repairs.remove_part")`).

- [ ] **Step 8: Write a locale-switching spec**

Create `spec/requests/locale_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe "Locale switching", type: :request do
  before { sign_in create(:user) }

  it "renders English by default" do
    get clients_path
    expect(response.body).to include("Clients")
  end

  it "renders Portuguese when ?locale=pt" do
    get clients_path(locale: :pt)
    expect(response.body).to include("Clientes")
  end
end
```

- [ ] **Step 9: Run the full suite**

Run: `bundle exec rspec`
Expected: all examples pass (no failures, no regressions from the string replacements).

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Add English/Portuguese locales for all user-facing text"
```

---

### Task 12: Development seed data

**Files:**
- Modify: `db/seeds.rb`

**Interfaces:**
- Consumes: `User` (Task 2).
- Produces: a runnable `bin/rails db:seed` that creates one admin account for local development login.

- [ ] **Step 1: Write the seed script**

Edit `db/seeds.rb` (replace its contents):
```ruby
User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = "password123"
  user.role = :admin
end
```

- [ ] **Step 2: Run it and verify**

Run: `bin/rails db:seed`
Then: `bin/rails runner 'puts User.find_by(email: "admin@example.com").admin?'`
Expected: prints `true`.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Add development seed for an admin user"
```

---

## Final Verification

After Task 12, run the full suite once more to confirm nothing regressed across all tasks:

```bash
bundle exec rspec
```
Expected: all examples pass, 0 failures.
