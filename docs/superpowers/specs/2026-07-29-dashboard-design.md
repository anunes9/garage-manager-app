# Dashboard Homepage — Design

## Purpose

Give the signed-in user a landing page that summarizes shop activity (client,
car, and repair counts) and surfaces the most common actions (create a
client/car/repair, search for a car by plate) without navigating into a
specific resource's index first.

## Routing

New `DashboardController#index` becomes the root route:

```ruby
root "dashboard#index"
```

This replaces the current `root "clients#index"`. `clients_path` still works
and the Clients nav link is unchanged; only what "/" resolves to changes.

## Data

`DashboardController#index` loads four counts, no service object or
background job — these are simple, fast aggregate queries:

```ruby
@clients_count = Client.count
@cars_count = Car.count
@repairs_count = Repair.count
@repairs_this_month_count = Repair.where(date: Date.current.all_month).count
```

`Repair#date` (the service date, already used throughout the app as the
meaningful "when was the work done" field) is the basis for "this month",
not `created_at`. `Date.current.all_month` gives the first-to-last day range
for the current month regardless of month length.

## UI layout

`app/views/dashboard/index.html.erb`:

1. `shared/page_head` partial — title "Dashboard", eyebrow "Overview". No CTA
   button (the quick actions section below covers that).
2. A responsive grid of 4 stat cards, one per KPI (Clients, Cars, Repairs,
   Repairs This Month), using a new `.stat-card` CSS component built on the
   existing `.card` base (same border/background/radius), with a large
   mono/display number and a small uppercase label — visually consistent with
   `.title-display` / `.eyebrow` already used elsewhere.
3. A "Quick Actions" section: a heading + a row of 4 buttons using the
   existing `.btn-primary` / `.btn-secondary` styles:
   - New Client → `new_client_path`
   - New Car → `new_car_path`
   - New Repair → `new_repair_path`
   - Search Car → `search_cars_path` (reuses the existing plate-search page;
     no new search UI)

## Nav integration

Add a "Home" link as the first item in the nav link row in
`app/views/layouts/application.html.erb`, active when
`controller_name == "dashboard"`, pointing to `root_path`.

## Post-login redirect

`ApplicationController#after_sign_in_path_for` currently hardcodes
`clients_path`, overriding Devise's default of `root_path`. Left as-is, users
would never actually land on the new dashboard after signing in — only by
clicking "Home" afterward. Since the point of this page is to be the landing
experience, `after_sign_in_path_for` is removed so Devise falls back to its
default (`root_path`, now the dashboard).

## i18n

New `dashboard:` namespace in `config/locales/en.yml` and
`config/locales/pt.yml`:

- `title` ("Dashboard" / "Painel")
- `eyebrow` ("Overview" / "Resumo")
- `stats.clients`, `stats.cars`, `stats.repairs`, `stats.repairs_this_month`
- `quick_actions.title` ("Quick Actions" / "Ações Rápidas")
- `quick_actions.new_client`, `quick_actions.new_car`, `quick_actions.new_repair`,
  `quick_actions.search_car` (can reuse existing `cars.new` / `clients.new` /
  `repairs.new` / `cars.search.title` keys where the wording already fits,
  rather than duplicating strings)

New `nav.home` key for the nav link label.

## Out of scope

- No charts/graphs — KPIs are plain numbers.
- No date-range picker for the monthly stat — it's always "this calendar
  month", not configurable.
- No per-client or per-car breakdowns on this page.
- No caching/memoization of the counts — traffic and table sizes are small
  enough that four `COUNT(*)` queries per request is not a concern.

## Testing

- Request spec: visiting `/` as a signed-in user renders the four KPI counts
  correctly (seed a known number of clients/cars/repairs, including at least
  one repair outside the current month, and assert the monthly count excludes
  it).
- System spec: sign in, land on the dashboard, click each of the four quick
  action buttons and confirm it navigates to the expected page
  (`new_client_path`, `new_car_path`, `new_repair_path`, `search_cars_path`).
- `spec/system/login_spec.rb` currently asserts `have_current_path(clients_path)`
  after sign-in; update it to expect the dashboard (`root_path`) instead, per
  the post-login redirect change above.
- `spec/requests/admin_access_spec.rb` already asserts a non-admin is
  redirected to `root_path` generically (no content assumption) — no change
  needed there.
