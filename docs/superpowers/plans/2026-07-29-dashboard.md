# Dashboard Homepage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give signed-in users a dashboard homepage at `/` showing client/car/repair KPI counts, a "repairs this month" count, and quick-action buttons for the most common create/search flows.

**Architecture:** A new `DashboardController#index` becomes the root route, replacing `clients#index`. It loads four plain `.count` queries (no service object, no caching) and renders a view built from existing design-system CSS components (`.card`, `.btn-secondary`, `.title-display`) plus two new small CSS components (`.stat-grid`, `.stat-card`). A "Home" nav link is added, and the post-login redirect (currently hardcoded to `clients_path`) is removed so users actually land on the new dashboard after signing in.

**Tech Stack:** Ruby on Rails 8, ERB views, Tailwind CSS v4 (`@layer components` pattern already in use), RSpec + Capybara/Selenium headless Chrome for system specs, FactoryBot, Devise.

## Global Constraints

- Follow existing i18n convention: every user-facing string goes through `t("...")` with both `config/locales/en.yml` and `config/locales/pt.yml` updated together.
- Reuse existing CSS components (`.card`, `.btn-secondary`, `.title-display`, `.eyebrow`) rather than inventing new visual language; only add CSS for things that don't already exist (the stat cards' grid/number/label treatment).
- Reuse existing locale keys for quick-action labels (`clients.new`, `cars.new`, `repairs.new`, `nav.search`) instead of duplicating strings under a new namespace.
- Request specs follow the existing pattern: `RSpec.describe "X", type: :request do; before { sign_in create(:user) }; ...`. System specs use the same `sign_in create(:user)` pattern and Capybara `click_on` / `have_current_path`.
- `spec/rails_helper.rb` has `config.use_transactional_fixtures = true`, so every request/system spec starts from an empty (migrated) database — counts created in a test are the only rows that exist.

---

### Task 1: Dashboard page — controller, view, styles, i18n, and root route

**Files:**
- Create: `app/controllers/dashboard_controller.rb`
- Create: `app/views/dashboard/index.html.erb`
- Modify: `config/routes.rb:22`
- Modify: `config/locales/en.yml` (add `dashboard:` namespace)
- Modify: `config/locales/pt.yml` (add `dashboard:` namespace)
- Modify: `app/assets/tailwind/application.css:106` (insert new component block right after `.card`)
- Test: `spec/requests/dashboard_spec.rb` (new)
- Test: `spec/system/dashboard_spec.rb` (new)

**Interfaces:**
- Produces: route `root_path` → `DashboardController#index`. View instance variables `@clients_count`, `@cars_count`, `@repairs_count`, `@repairs_this_month_count` (all `Integer`). CSS classes `.stat-grid`, `.stat-card`, `.stat-card__value`, `.stat-card__label`. Locale keys `dashboard.title`, `dashboard.eyebrow`, `dashboard.stats.clients`, `dashboard.stats.cars`, `dashboard.stats.repairs`, `dashboard.stats.repairs_this_month`, `dashboard.quick_actions`.
- Consumes: existing `Client`, `Car`, `Repair` models (`.count`, `Repair.where(date: range)`), existing routes `new_client_path`, `new_car_path`, `new_repair_path`, `search_cars_path`, existing locale keys `clients.new`, `cars.new`, `repairs.new`, `nav.search`, existing `shared/page_head` partial (`title:`, `eyebrow:` locals).

- [ ] **Step 1: Write the failing request spec**

Create `spec/requests/dashboard_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  before { sign_in create(:user) }

  it "shows KPI counts for clients, cars, total repairs, and repairs this month" do
    clients = create_list(:client, 2)
    cars = create_list(:car, 4, client: clients.first)
    create_list(:repair, 5, car: cars.first, date: Date.current)
    create_list(:repair, 2, car: cars.first, date: 1.month.ago.to_date)

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('class="stat-card__value">2<')
    expect(response.body).to include('class="stat-card__value">4<')
    expect(response.body).to include('class="stat-card__value">7<')
    expect(response.body).to include('class="stat-card__value">5<')
  end
end
```

- [ ] **Step 2: Run the request spec to verify it fails**

Run: `bundle exec rspec spec/requests/dashboard_spec.rb`
Expected: FAIL — root still routes to `clients#index`, so the response body has no `stat-card__value` markup at all.

- [ ] **Step 3: Write the failing system spec**

Create `spec/system/dashboard_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Dashboard quick actions", type: :system do
  before { sign_in create(:user) }

  it "opens the new client form" do
    visit root_path
    click_on I18n.t("clients.new")
    expect(page).to have_current_path(new_client_path)
  end

  it "opens the new car form" do
    visit root_path
    click_on I18n.t("cars.new")
    expect(page).to have_current_path(new_car_path)
  end

  it "opens the new repair form" do
    visit root_path
    click_on I18n.t("repairs.new")
    expect(page).to have_current_path(new_repair_path)
  end

  it "opens the car search page" do
    visit root_path
    click_on I18n.t("nav.search")
    expect(page).to have_current_path(search_cars_path)
  end
end
```

- [ ] **Step 4: Run the system spec to verify it fails**

Run: `bundle exec rspec spec/system/dashboard_spec.rb`
Expected: FAIL — visiting `root_path` currently renders the Clients index, which has no "New Client"/"New Car"/"New Repair"/"Search plate" links on it as a group (it does have a "New Client" CTA in its own page_head, so this may partially "pass" by accident for that one link, but "New Car", "New Repair", and "Search plate" are not present there, so those three examples fail).

- [ ] **Step 5: Change the root route**

In `config/routes.rb`, replace:

```ruby
  root "clients#index"
```

with:

```ruby
  root "dashboard#index"
```

- [ ] **Step 6: Add the controller**

Create `app/controllers/dashboard_controller.rb`:

```ruby
class DashboardController < ApplicationController
  def index
    @clients_count = Client.count
    @cars_count = Car.count
    @repairs_count = Repair.count
    @repairs_this_month_count = Repair.where(date: Date.current.all_month).count
  end
end
```

- [ ] **Step 7: Add locale keys**

In `config/locales/en.yml`, add `home: "Home"` as the first key inside the existing `nav:` block (immediately after `nav:` and before `clients:`):

```yaml
  nav:
    home: "Home"
    clients: "Clients"
```

Then add a new top-level `dashboard:` block, inserted immediately after the `parts:` block and before the `settings:` block:

```yaml
  dashboard:
    title: "Dashboard"
    eyebrow: "Overview"
    stats:
      clients: "Clients"
      cars: "Cars"
      repairs: "Repairs"
      repairs_this_month: "Repairs This Month"
    quick_actions: "Quick Actions"
```

In `config/locales/pt.yml`, add `home: "Início"` as the first key inside `nav:`:

```yaml
  nav:
    home: "Início"
    clients: "Clientes"
```

Then add the matching `dashboard:` block, inserted immediately after `parts:` and before `settings:`:

```yaml
  dashboard:
    title: "Painel"
    eyebrow: "Resumo"
    stats:
      clients: "Clientes"
      cars: "Carros"
      repairs: "Reparações"
      repairs_this_month: "Reparações Este Mês"
    quick_actions: "Ações Rápidas"
```

- [ ] **Step 8: Add the stat-card CSS component**

In `app/assets/tailwind/application.css`, immediately after the closing `}` of the existing `.card` rule (the block starting `.card {` around line 100) and before the `/* Buttons ... */` comment, insert:

```css

  .stat-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
    margin-bottom: 2.5rem;
  }
  @media (min-width: 640px) {
    .stat-grid {
      grid-template-columns: repeat(4, 1fr);
    }
  }
  .stat-card {
    padding: 1.25rem 1.5rem;
  }
  .stat-card__value {
    display: block;
    font-family: var(--font-display);
    font-size: 2.5rem;
    line-height: 1;
  }
  .stat-card__label {
    display: block;
    margin-top: 0.35rem;
    font-family: var(--font-mono);
    font-size: 0.75rem;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--color-muted);
  }
```

- [ ] **Step 9: Add the view**

Create `app/views/dashboard/index.html.erb`:

```erb
<%= render "shared/page_head", title: t("dashboard.title"), eyebrow: t("dashboard.eyebrow") %>

<div class="stat-grid">
  <div class="card stat-card">
    <span class="stat-card__value"><%= @clients_count %></span>
    <span class="stat-card__label"><%= t("dashboard.stats.clients") %></span>
  </div>
  <div class="card stat-card">
    <span class="stat-card__value"><%= @cars_count %></span>
    <span class="stat-card__label"><%= t("dashboard.stats.cars") %></span>
  </div>
  <div class="card stat-card">
    <span class="stat-card__value"><%= @repairs_count %></span>
    <span class="stat-card__label"><%= t("dashboard.stats.repairs") %></span>
  </div>
  <div class="card stat-card">
    <span class="stat-card__value"><%= @repairs_this_month_count %></span>
    <span class="stat-card__label"><%= t("dashboard.stats.repairs_this_month") %></span>
  </div>
</div>

<h2 class="title-display text-2xl mb-4"><%= t("dashboard.quick_actions") %></h2>
<div class="flex flex-wrap gap-4">
  <%= link_to t("clients.new"), new_client_path, class: "btn-secondary w-full sm:w-auto" %>
  <%= link_to t("cars.new"), new_car_path, class: "btn-secondary w-full sm:w-auto" %>
  <%= link_to t("repairs.new"), new_repair_path, class: "btn-secondary w-full sm:w-auto" %>
  <%= link_to t("nav.search"), search_cars_path, class: "btn-secondary w-full sm:w-auto" %>
</div>
```

- [ ] **Step 10: Run both specs to verify they pass**

Run: `bundle exec rspec spec/requests/dashboard_spec.rb spec/system/dashboard_spec.rb`
Expected: PASS (5 examples, 0 failures).

- [ ] **Step 11: Run the full suite to check for regressions**

Run: `bundle exec rspec`
Expected: PASS. (The root route change does not affect `spec/system/login_spec.rb`, since post-login redirect is currently hardcoded to `clients_path` in `ApplicationController#after_sign_in_path_for`, independent of the root route — that hardcoding is removed in Task 3. `spec/requests/admin_access_spec.rb`'s `redirect_to(root_path)` assertion is unaffected since it doesn't check page content.)

- [ ] **Step 12: Commit**

```bash
git add app/controllers/dashboard_controller.rb app/views/dashboard/index.html.erb \
  config/routes.rb config/locales/en.yml config/locales/pt.yml \
  app/assets/tailwind/application.css \
  spec/requests/dashboard_spec.rb spec/system/dashboard_spec.rb
git commit -m "Add dashboard homepage with KPI counts and quick actions"
```

---

### Task 2: "Home" nav link

**Files:**
- Modify: `app/views/layouts/application.html.erb:44`
- Test: `spec/system/dashboard_spec.rb` (append one example)

**Interfaces:**
- Consumes: `root_path` route produced in Task 1, Step 5; the `t("nav.home")` key added in Task 1, Step 7; the nav's existing `nav-link` / `is-active` pattern (`app/views/layouts/application.html.erb:44-46`).
- Produces: nothing new consumed by later tasks.

- [ ] **Step 1: Write the failing system spec example**

Append to `spec/system/dashboard_spec.rb` (inside the existing `RSpec.describe` block, after the last `it`):

```ruby

  it "is reachable from a Home link in the nav" do
    visit clients_path
    click_on I18n.t("nav.home")
    expect(page).to have_current_path(root_path)
  end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bundle exec rspec spec/system/dashboard_spec.rb -e "is reachable from a Home link in the nav"`
Expected: FAIL — no element with the text "Home" exists in the nav yet.

- [ ] **Step 3: Add the nav link**

In `app/views/layouts/application.html.erb`, immediately before the existing Clients nav link (`<%= link_to t("nav.clients"), clients_path, ... %>`, around line 44), insert:

```erb
          <%= link_to t("nav.home"), root_path, class: "nav-link #{"is-active" if controller_name == "dashboard"}" %>
```

- [ ] **Step 4: Run it to verify it passes**

Run: `bundle exec rspec spec/system/dashboard_spec.rb`
Expected: PASS (6 examples, 0 failures).

- [ ] **Step 5: Run the full suite to check for regressions**

Run: `bundle exec rspec`
Expected: PASS. (Existing specs check for `nav-link`-classed Clients/Cars/Repairs links by their own text, not by position, so inserting a new link ahead of them does not break any existing assertion.)

- [ ] **Step 6: Commit**

```bash
git add app/views/layouts/application.html.erb spec/system/dashboard_spec.rb
git commit -m "Add a Home nav link to the dashboard"
```

---

### Task 3: Land on the dashboard after signing in

**Files:**
- Modify: `app/controllers/application_controller.rb:11-13`
- Modify: `spec/system/login_spec.rb:9-16`

**Interfaces:**
- Consumes: `root_path` → dashboard, produced in Task 1.
- Produces: nothing consumed by later tasks (final task in this plan).

- [ ] **Step 1: Update the failing expectation first**

In `spec/system/login_spec.rb`, replace the first example:

```ruby
  it "signs in with valid credentials and lands on the clients index" do
    visit new_user_session_path

    fill_in "Email", with: "manager@example.com"
    fill_in "Password", with: "password123"
    click_on "Sign in"

    expect(page).to have_current_path(clients_path)
    expect(page).to have_content("Clients")
    within("nav") { expect(page).to have_content("manager@example.com") }
  end
```

with:

```ruby
  it "signs in with valid credentials and lands on the dashboard" do
    visit new_user_session_path

    fill_in "Email", with: "manager@example.com"
    fill_in "Password", with: "password123"
    click_on "Sign in"

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Dashboard")
    within("nav") { expect(page).to have_content("manager@example.com") }
  end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bundle exec rspec spec/system/login_spec.rb -e "signs in with valid credentials and lands on the dashboard"`
Expected: FAIL — `ApplicationController#after_sign_in_path_for` still hardcodes `clients_path`, so `have_current_path(root_path)` fails.

- [ ] **Step 3: Remove the hardcoded redirect**

In `app/controllers/application_controller.rb`, delete:

```ruby
  def after_sign_in_path_for(resource)
    clients_path
  end

```

leaving `authenticate_user!` / `around_action :switch_locale` followed directly by `switch_locale` method definition. Devise's own `after_sign_in_path_for` default (`stored_location_for(resource) || root_path`) takes over, landing the user on the new dashboard root.

- [ ] **Step 4: Run it to verify it passes**

Run: `bundle exec rspec spec/system/login_spec.rb`
Expected: PASS (3 examples, 0 failures).

- [ ] **Step 5: Run the full suite to check for regressions**

Run: `bundle exec rspec`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/application_controller.rb spec/system/login_spec.rb
git commit -m "Land signed-in users on the dashboard instead of Clients"
```
