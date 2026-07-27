# Garage Manager v2 — Design

## 1. Overview

v2 is a full rewrite of the Garage Manager app on Ruby on Rails, replacing the current
React + Refine + Mantine + Appwrite stack. It carries forward v1's core functionality
(Clients, Cars, Repairs) and adds real user accounts with two roles: **Admin** and
**GarageManager**.

This is a port-plus-improvements effort, not a like-for-like port: the rewrite keeps
v1's data model and features (with `Budget` renamed to `Repair`) while introducing
authentication and role-based access.

## 2. Stack

- **Rails 8**, monolith
- **PostgreSQL**
- **Hotwire (Turbo + Stimulus)** for the main app UI
- **Tailwind CSS** for styling
- **Devise** for authentication
- **ActiveAdmin** mounted at `/admin` for user account management
- **RSpec** for testing
- **Rails I18n**, English and Portuguese locales (mirrors v1's en/pt setup)

No data migration from the v1 Appwrite backend — v2 starts with a fresh database.

## 3. Data Models

### User (Devise)

- `email`, encrypted `password`
- `role` enum: `admin`, `garage_manager`
- Created only by an Admin via ActiveAdmin. No public registration.
- The creating Admin sets the initial password directly in the ActiveAdmin form —
  no invite emails or mailer setup required.

### Client

- `name`, `phone`
- Plain record, same as v1. **Clients do not log in** — there is no client-facing
  portal in this design.
- `has_many :cars`

### Car

- `brand`, `model`, `plate`
- `belongs_to :client`
- `has_many :repairs`

### Repair (renamed from v1's `Budget`)

- `date`, `km`, `total` (computed from its parts, same as v1)
- `notes` long string
- `belongs_to :car`
- `has_many :parts`

### Part

- `name`, `quantity`, `price`
- `belongs_to :repair`
- Modeled as a real relational table (not a JSON/serialized column), added to a
  Repair via Rails nested attributes. This is the one deliberate structural change
  from v1's Appwrite document-embedded parts array — it's more idiomatic Rails and
  plays well with nested forms.

## 4. Roles & Permissions

Both roles work off the same shared pool of Clients/Cars/Repairs — **this is not a
multi-tenant system**. GarageManagers are not siloed from each other's data.

- **Admin**: full CRUD on Clients, Cars, and Repairs via the main app (same as
  GarageManager), **plus** exclusive access to ActiveAdmin at `/admin` to create and
  manage User accounts (both Admin and GarageManager).
- **GarageManager**: full CRUD on Clients, Cars, and Repairs via the main app. No
  access to ActiveAdmin or user management.

Enforcement is a plain `role` enum on `User` with helper methods (`user.admin?`,
`user.garage_manager?`) and controller `before_action` guards. No authorization gem
(Pundit/CanCanCan) — the two-role split is simple enough not to warrant one.

## 5. Authentication

- Single Devise-backed `User` model serves both the main Hotwire app and ActiveAdmin
  logins.
- No public sign-up. Accounts are created exclusively by Admins through ActiveAdmin.

## 6. ActiveAdmin Scope

- Mounted at `/admin`, accessible only to `admin`-role users.
- Manages **only** the `User` resource (create/edit Admin and GarageManager
  accounts).
- Does **not** expose Clients, Cars, Repairs, or Parts — those live in the main app
  for both roles.

## 7. Main App (Hotwire) Scope

- Both `admin` and `garage_manager` users land here after login.
- Full CRUD for:
  - **Clients** (name, phone)
  - **Cars** (brand, model, plate, client)
  - **Repairs** (date, km, car, parts, computed total)
- Parts are managed as nested attributes on the Repair form — dynamically
  add/remove line-item rows via Stimulus, mirroring v1's Mantine dynamic-list UX.
- No per-user data scoping: all authenticated users see the same Clients, Cars, and
  Repairs.

## 8. i18n

English and Portuguese locales, maintained via Rails I18n — carrying forward v1's
bilingual UI.

## 9. Testing

RSpec: model specs, request specs, and system specs for key flows (login, Client/Car/
Repair CRUD, ActiveAdmin user management).

## 10. Out of Scope

- No client-facing login or portal — Clients remain passive records.
- No multi-tenancy — GarageManagers share one data pool.
- No email delivery/mailer setup — Admin sets passwords directly.
- No data migration from the v1 Appwrite database.
