# Plate Search — Design

## Purpose

Let a user, from anywhere in the app, find a car by its (partial) plate and jump
straight to that car's page, which already shows the owning client and the full
repair history. Today the only way to find a car is to browse the Cars list.

## Entry point

An icon button is added to the global nav (`app/views/layouts/application.html.erb`),
next to the sign-out button. Clicking it reveals a search input inline in the nav.
The input is available from every authenticated page.

## Live results

Implemented with a Turbo Frame — no custom fetch/XHR code:

- The input lives inside a `form_with url: search_cars_path, method: :get`,
  which targets `turbo_frame_tag "car_search_results"`. The frame is positioned
  as a dropdown directly under the input (`position: absolute`).
- A Stimulus controller (`app/javascript/controllers/car_search_controller.js`)
  debounces keystrokes (~300ms) and calls `requestSubmit()` on the form. Turbo
  swaps the frame's contents in place — no full-page navigation.
- The controller also:
  - closes the dropdown on click-outside or `Escape`
  - clears/hides the dropdown when the input is emptied
  - on `Enter`, if the dropdown currently shows exactly one result, navigates
    the browser straight to that car's page
- The search only runs once the query is 2+ characters, to avoid dumping the
  whole table on a stray keystroke.

## Backend

- New collection route: `GET /cars/search` → `CarsController#search`
- Query: `Car.includes(:client).where("plate ILIKE ?", "%#{q}%").order(:plate)`
  (case-insensitive substring match; Postgres `ILIKE`)
- Renders `app/views/cars/_search_results.html.erb`, wrapped in the same
  `turbo_frame_tag "car_search_results"` id, listing each match as a row with:
  plate badge, brand/model, client name — each row links to `car_path(car)`.
- Empty state: "No cars found" rendered inside the frame when there are 0 matches.
- No changes to `cars#index` or `cars#show` — this is purely additive. The
  existing `cars#show` page already displays the client and all repairs for
  the car, so no new "car detail" view is needed.

## i18n

New keys added to both `config/locales/en.yml` and `config/locales/pt.yml`:

- `nav.search` — label/aria-label for the nav search button/input
- `cars.search.placeholder` — input placeholder text
- `cars.search.no_results` — "No cars found" empty state message

## Out of scope

- No dedicated full-page search results view (dropdown only).
- No fuzzy/typo-tolerant matching — plain substring `ILIKE`.
- No keyboard arrow-key navigation between dropdown results.
- No search across brand/model/client name — plate only, per the request.

## Testing

- Request/controller spec for `CarsController#search`: matches by substring,
  case-insensitively; empty query or no matches renders the empty state;
  multiple matches all render.
- System spec: type a partial plate into the nav search, see the dropdown
  populate, click a result, land on that car's show page.
