# Plate Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a signed-in user search for a car by (partial) plate from a search box in the global nav, and jump straight to that car's page (which already shows its client and full repair history).

**Architecture:** A `GET /cars/search` collection route on `CarsController` renders matches (case-insensitive substring match on `plate`) inside a Turbo Frame. A small Stimulus controller in the nav debounces keystrokes and resubmits the search form into that frame, giving a live dropdown with zero custom fetch/XHR code. No new "car detail" view is needed — clicking a result links to the existing `car_path`.

**Tech Stack:** Ruby on Rails 8, Hotwire (Turbo Frames + Stimulus via importmap), RSpec + Capybara/Selenium (`driven_by :selenium, using: :headless_chrome`, already configured for all system specs), FactoryBot, Tailwind v4 (`app/assets/tailwind/application.css`, hand-written component classes, no component library).

## Global Constraints

- Postgres is the database (`config/database.yml`); use `ILIKE` for case-insensitive matching.
- Search only runs once the query is 2+ characters (spec: "avoids dumping the whole table on a stray keystroke").
- No dedicated full-page search results view — dropdown only.
- No fuzzy matching — plain substring `ILIKE`.
- No keyboard arrow-key navigation between results.
- Search is plate-only — not brand/model/client name.
- All user-facing copy goes through i18n (`config/locales/en.yml` and `config/locales/pt.yml`), matching this app's existing bilingual setup.
- Follow existing code style: no comments unless explaining non-obvious "why"; reuse existing CSS component classes (`.card`, `.field-input`, `.plate-badge`, etc.) rather than inventing parallel ones where one already fits.

---

### Task 1: Search route, controller action, and results partial

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/controllers/cars_controller.rb`
- Create: `app/views/cars/search.html.erb`
- Create: `app/views/cars/_search_results.html.erb`
- Modify: `config/locales/en.yml`
- Modify: `config/locales/pt.yml`
- Test: `spec/requests/cars_spec.rb`

**Interfaces:**
- Produces: route helper `search_cars_path` (GET, accepts `q` param), `CarsController#search` (sets `@cars`), partial `cars/_search_results` (locals: `cars:`) rendered inside `turbo_frame_tag "car_search_results"` with `data-car-search-target="results"` — Task 3's Stimulus controller looks up elements with `data-car-search-target="resultLink"` inside that frame.
- Consumes: `Car` model (`plate`, `brand`, `model`, `client`), `plate_badge` helper (`app/helpers/application_helper.rb`).

- [ ] **Step 1: Write the failing request specs**

Append to `spec/requests/cars_spec.rb` (inside the existing `RSpec.describe "Cars", type: :request do ... end` block, after the last `it`):

```ruby
  it "finds cars by partial, case-insensitive plate match" do
    create(:car, plate: "AA-11-BB")
    create(:car, plate: "cc-22-dd")
    get search_cars_path, params: { q: "aa-11" }
    expect(response.body).to include("AA-11-BB")
    expect(response.body).not_to include("CC-22-DD")
  end

  it "shows every match when the query matches more than one plate" do
    create(:car, plate: "AA-11-BB")
    create(:car, plate: "AA-12-BB")
    get search_cars_path, params: { q: "AA-1" }
    expect(response.body).to include("AA-11-BB")
    expect(response.body).to include("AA-12-BB")
  end

  it "shows an empty state when nothing matches" do
    get search_cars_path, params: { q: "ZZ-99" }
    expect(response.body).to include(I18n.t("cars.search.no_results"))
  end

  it "does not search with fewer than 2 characters" do
    create(:car, plate: "AA-11-BB")
    get search_cars_path, params: { q: "A" }
    expect(response.body).to include(I18n.t("cars.search.no_results"))
  end
```

- [ ] **Step 2: Run the specs to verify they fail**

Run: `bundle exec rspec spec/requests/cars_spec.rb`
Expected: FAIL — `search_cars_path` is undefined (no route yet).

- [ ] **Step 3: Add the route**

In `config/routes.rb`, replace:

```ruby
  resources :cars
```

with:

```ruby
  resources :cars do
    collection do
      get :search
    end
  end
```

- [ ] **Step 4: Add the controller action**

In `app/controllers/cars_controller.rb`, add a `search` action (place it after `def show` / `end`, before `def new`):

```ruby
  def search
    query = params[:q].to_s.strip
    @cars = if query.length >= 2
      Car.includes(:client).where("plate ILIKE ?", "%#{query}%").order(:plate)
    else
      Car.none
    end
  end
```

- [ ] **Step 5: Add the i18n keys**

In `config/locales/en.yml`, inside the `cars:` block, add a `search:` key (place it after `fields:` block, before `created:`):

```yaml
    search:
      placeholder: "Search by plate…"
      no_results: "No cars found."
```

In `config/locales/pt.yml`, inside the `cars:` block, in the same position:

```yaml
    search:
      placeholder: "Pesquisar por matrícula…"
      no_results: "Nenhum carro encontrado."
```

- [ ] **Step 6: Add the results partial**

Note: each result link is tagged `data-turbo-frame="_top"`. Without it, Turbo
would treat the link as scoped to the enclosing `car_search_results` frame and
try to load the car's page *inside* the small dropdown instead of navigating
the whole page.

Create `app/views/cars/_search_results.html.erb`:

```erb
<%= turbo_frame_tag "car_search_results", data: { car_search_target: "results" } do %>
  <% if cars.any? %>
    <ul class="search-results">
      <% cars.each do |car| %>
        <li class="search-result">
          <%= link_to car_path(car), class: "search-result__link", data: { turbo_frame: "_top", car_search_target: "resultLink" } do %>
            <%= plate_badge(car.plate) %>
            <span class="search-result__meta"><%= "#{car.brand} #{car.model} · #{car.client.name}" %></span>
          <% end %>
        </li>
      <% end %>
    </ul>
  <% else %>
    <p class="search-empty"><%= t("cars.search.no_results") %></p>
  <% end %>
<% end %>
```

- [ ] **Step 7: Add the search template**

Create `app/views/cars/search.html.erb`:

```erb
<%= render "search_results", cars: @cars %>
```

- [ ] **Step 8: Run the specs to verify they pass**

Run: `bundle exec rspec spec/requests/cars_spec.rb`
Expected: PASS (all examples, including the pre-existing ones).

- [ ] **Step 9: Commit**

```bash
git add config/routes.rb app/controllers/cars_controller.rb app/views/cars/search.html.erb app/views/cars/_search_results.html.erb config/locales/en.yml config/locales/pt.yml spec/requests/cars_spec.rb
git commit -m "Add plate search endpoint"
```

---

### Task 2: Nav search widget (markup + styling, no live behavior yet)

**Files:**
- Create: `app/views/shared/_plate_search.html.erb`
- Modify: `app/views/layouts/application.html.erb`
- Modify: `app/assets/tailwind/application.css`
- Modify: `config/locales/en.yml`
- Modify: `config/locales/pt.yml`
- Test: `spec/requests/clients_spec.rb`

**Interfaces:**
- Produces: the DOM structure Task 3's Stimulus controller (`data-controller="car-search"`) attaches to — a root element with that `data-controller`, a toggle button (`data-action="car-search#toggle"`), a panel with `data-car-search-target="container"`, a `form_with` targeting `search_cars_path` with `data-turbo-frame: "car_search_results"` and `data-car-search-target="form"`, a text field with `data-car-search-target="input"`, and the `turbo_frame_tag "car_search_results"` with `data-car-search-target="results"` from Task 1.
- Consumes: `search_cars_path` (Task 1), `t("nav.search")`, `t("cars.search.placeholder")`.

- [ ] **Step 1: Write the failing request spec**

Append to `spec/requests/clients_spec.rb` (inside its existing `RSpec.describe` block):

```ruby
  it "shows the plate search control in the nav" do
    get clients_path
    expect(response.body).to include(I18n.t("nav.search"))
  end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `bundle exec rspec spec/requests/clients_spec.rb`
Expected: FAIL — `I18n.t("nav.search")` translation missing (or nav markup absent).

- [ ] **Step 3: Add the `nav.search` i18n key**

In `config/locales/en.yml`, inside the `nav:` block, after `sign_out: "Sign out"`:

```yaml
    search: "Search plate"
```

In `config/locales/pt.yml`, inside the `nav:` block, after `sign_out: "Sair"`:

```yaml
    search: "Pesquisar matrícula"
```

- [ ] **Step 4: Create the nav search partial**

Create `app/views/shared/_plate_search.html.erb`:

```erb
<div class="nav-search" data-controller="car-search">
  <button type="button" class="nav-search__toggle" aria-label="<%= t("nav.search") %>" data-action="car-search#toggle">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" class="nav-search__icon" aria-hidden="true">
      <circle cx="9" cy="9" r="6"></circle>
      <line x1="18" y1="18" x2="13.5" y2="13.5"></line>
    </svg>
  </button>

  <div class="nav-search__panel hidden" data-car-search-target="container">
    <%= form_with url: search_cars_path, method: :get, data: { turbo_frame: "car_search_results", car_search_target: "form" } do |f| %>
      <%= f.text_field :q,
            placeholder: t("cars.search.placeholder"),
            autocomplete: "off",
            class: "field-input nav-search__input",
            data: { car_search_target: "input", action: "input->car-search#submit keydown->car-search#keydown" } %>
    <% end %>

    <%= turbo_frame_tag "car_search_results", data: { car_search_target: "results" } %>
  </div>
</div>
```

- [ ] **Step 5: Wire the partial into the layout**

In `app/views/layouts/application.html.erb`, find:

```erb
          <div class="flex items-center gap-3 sm:gap-5">
            <span class="hidden sm:inline text-sm font-mono text-gray-400"><%= current_user.email %></span>
            <%= button_to t("nav.sign_out"), destroy_user_session_path, method: :delete, class: "nav-link bg-transparent border-0 p-0 cursor-pointer" %>
          </div>
```

Replace with:

```erb
          <div class="flex items-center gap-3 sm:gap-5">
            <%= render "shared/plate_search" %>
            <span class="hidden sm:inline text-sm font-mono text-gray-400"><%= current_user.email %></span>
            <%= button_to t("nav.sign_out"), destroy_user_session_path, method: :delete, class: "nav-link bg-transparent border-0 p-0 cursor-pointer" %>
          </div>
```

- [ ] **Step 6: Add the CSS**

In `app/assets/tailwind/application.css`, insert the following block right before the final closing `}` of `@layer components` (i.e. immediately after the `.detail-row` media query block, which currently ends the file):

```css

  /* Nav plate search */
  .nav-search {
    position: relative;
  }
  .nav-search__toggle {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 2.75rem;
    height: 2.75rem;
    color: #c9cdd1;
    background: none;
    border: 0;
    cursor: pointer;
    transition: color 0.15s ease;
  }
  .nav-search__toggle:hover {
    color: #fff;
  }
  .nav-search__icon {
    width: 1.25rem;
    height: 1.25rem;
  }
  .nav-search__panel {
    position: absolute;
    top: 100%;
    right: 0;
    z-index: 20;
    width: 18rem;
    max-width: calc(100vw - 2rem);
    margin-top: 0.5rem;
    background-color: #fff;
    border: 1px solid var(--color-paper-line);
    border-radius: 0.5rem;
    box-shadow: 0 4px 16px rgba(33, 28, 22, 0.15);
    padding: 0.75rem;
  }
  .nav-search__input {
    min-height: 2.75rem;
    padding: 0.6rem 0.85rem;
  }
  .search-results {
    margin-top: 0.5rem;
    max-height: 16rem;
    overflow-y: auto;
  }
  .search-result + .search-result {
    border-top: 1px solid var(--color-paper-line);
  }
  .search-result__link {
    display: flex;
    align-items: center;
    gap: 0.6rem;
    padding: 0.6rem 0.25rem;
    color: var(--color-ink);
  }
  .search-result__link:hover {
    background-color: var(--color-paper);
  }
  .search-result__meta {
    font-size: 0.85rem;
    color: var(--color-muted);
  }
  .search-empty {
    margin-top: 0.5rem;
    font-size: 0.9rem;
    color: var(--color-muted);
  }
```

- [ ] **Step 7: Run the spec to verify it passes**

Run: `bundle exec rspec spec/requests/clients_spec.rb`
Expected: PASS (all examples).

- [ ] **Step 8: Run the full existing suite to check for regressions**

Run: `bundle exec rspec`
Expected: PASS (all examples — the layout change touches every page).

- [ ] **Step 9: Commit**

```bash
git add app/views/shared/_plate_search.html.erb app/views/layouts/application.html.erb app/assets/tailwind/application.css config/locales/en.yml config/locales/pt.yml spec/requests/clients_spec.rb
git commit -m "Add plate search widget to nav"
```

---

### Task 3: Live search behavior (Stimulus controller) + end-to-end system spec

**Files:**
- Create: `app/javascript/controllers/car_search_controller.js`
- Test: `spec/system/car_search_spec.rb`

**Interfaces:**
- Consumes: DOM structure from Task 2 (`data-controller="car-search"`, targets `container`, `form`, `input`, `results`, and per-result `resultLink`) and the live endpoint from Task 1 (`search_cars_path` via the frame-targeted form).
- Produces: nothing consumed by later tasks — this is the last task in the plan.

- [ ] **Step 1: Write the failing system spec**

Create `spec/system/car_search_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Searching for a car by plate", type: :system do
  before { sign_in create(:user) }

  it "finds a car by partial plate and navigates to it" do
    client = create(:client, name: "João Silva")
    car = create(:car, plate: "AA-11-BB", brand: "Toyota", model: "Corolla", client: client)
    create(:car, plate: "CC-22-DD")

    visit clients_path
    find("[aria-label='#{I18n.t('nav.search')}']").click
    fill_in I18n.t("cars.search.placeholder"), with: "AA-1"

    within "#car_search_results" do
      expect(page).to have_content("AA-11-BB")
      expect(page).not_to have_content("CC-22-DD")
      click_on "AA-11-BB"
    end

    expect(page).to have_current_path(car_path(car))
    expect(page).to have_content("João Silva")
  end

  it "shows an empty state when no plate matches" do
    visit clients_path
    find("[aria-label='#{I18n.t('nav.search')}']").click
    fill_in I18n.t("cars.search.placeholder"), with: "ZZ-99"

    within "#car_search_results" do
      expect(page).to have_content(I18n.t("cars.search.no_results"))
    end
  end
end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `bundle exec rspec spec/system/car_search_spec.rb`
Expected: FAIL — the panel never opens / never updates (no Stimulus controller registered yet), so `within "#car_search_results"` won't find the expected content in time.

- [ ] **Step 3: Write the Stimulus controller**

Create `app/javascript/controllers/car_search_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "form", "input", "results"]

  connect() {
    this.debounceTimeout = null
    this.boundClickOutside = this.clickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggle() {
    const opening = this.containerTarget.classList.contains("hidden")
    this.containerTarget.classList.toggle("hidden")

    if (opening) {
      document.addEventListener("click", this.boundClickOutside)
      this.inputTarget.focus()
    } else {
      document.removeEventListener("click", this.boundClickOutside)
    }
  }

  close() {
    this.containerTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundClickOutside)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  submit() {
    clearTimeout(this.debounceTimeout)

    this.debounceTimeout = setTimeout(() => {
      if (this.inputTarget.value.trim().length >= 2) {
        this.formTarget.requestSubmit()
      } else {
        this.resultsTarget.innerHTML = ""
      }
    }, 300)
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
      return
    }

    if (event.key === "Enter") {
      const links = this.resultsTarget.querySelectorAll("[data-car-search-target='resultLink']")
      if (links.length === 1) {
        event.preventDefault()
        window.location = links[0].href
      }
    }
  }
}
```

- [ ] **Step 4: Run the spec to verify it passes**

Run: `bundle exec rspec spec/system/car_search_spec.rb`
Expected: PASS (both examples).

- [ ] **Step 5: Run the full suite to check for regressions**

Run: `bundle exec rspec`
Expected: PASS (all examples).

- [ ] **Step 6: Commit**

```bash
git add app/javascript/controllers/car_search_controller.js spec/system/car_search_spec.rb
git commit -m "Add live plate search behavior"
```
