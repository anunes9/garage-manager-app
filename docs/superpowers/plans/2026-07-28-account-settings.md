# Account Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a signed-in user change their own display name, language, and password from a self-service `/settings` page, and make the app's locale a persisted per-user preference instead of a `?locale=` URL param.

**Architecture:** Two new `users` columns (`name`, `locale`). `ApplicationController#switch_locale` reads `current_user&.locale` instead of a request param. A new `SettingsController` renders one page with two independent forms — a plain profile update (name + locale) and a Devise `update_with_password`-backed password change — each posting to its own route so changing your name never requires re-entering your password.

**Tech Stack:** Ruby on Rails 8, Devise 5 (`:database_authenticatable, :rememberable, :validatable` — no `:registerable`), RSpec + Capybara/Selenium, FactoryBot, Postgres.

## Global Constraints

- `name` is nullable, no presence validation — existing seeded users have none today.
- `locale` defaults to `"en"` at the DB level (`null: false, default: "en"`), validated with `inclusion: { in: I18n.available_locales.map(&:to_s) }`.
- The `?locale=` URL param mechanism is deleted entirely, not kept as a fallback: `requested_locale`, `valid_locale_param`, and the `default_url_options` override are removed from `ApplicationController`.
- Pre-login pages (Devise's own controllers) always render in English now — there is no `current_user` yet to read a locale from. This is intentional, not a bug to work around.
- Changing password re-signs the user in (`bypass_sign_in(current_user)`) since Devise invalidates the session-validating salt on password change.
- All user-facing copy goes through i18n (`config/locales/en.yml` / `pt.yml`), matching existing keys' style (flat, per-feature top-level namespace, `fields:` sub-key for form labels).
- Follow existing patterns: controllers mirror `ClientsController`/`CarsController` (`render :edit, status: :unprocessable_entity` on failure), views reuse `.card`, `.field-label`, `.field-input`, `.btn-primary`, `.form-error-box` from `app/assets/tailwind/application.css` — no new CSS needed for this feature.

---

### Task 1: `name`/`locale` columns and User validation

**Files:**
- Create: a new migration (via generator, filename timestamp is generated at run time)
- Modify: `app/models/user.rb`
- Test: `spec/models/user_spec.rb`

**Interfaces:**
- Produces: `User#name` (string, nullable), `User#locale` (string, `"en"`/`"pt"`, DB default `"en"`), model validation rejecting any locale not in `I18n.available_locales`.
- Consumes: `I18n.available_locales` (already configured as `[:en, :pt]` in `config/application.rb`).

- [ ] **Step 1: Write the failing model specs**

Append to `spec/models/user_spec.rb`, inside the existing `RSpec.describe User, type: :model do ... end` block, after the last example:

```ruby
  describe "#locale" do
    it "is valid for each available locale" do
      I18n.available_locales.each do |locale|
        expect(build(:user, locale: locale.to_s)).to be_valid
      end
    end

    it "is invalid for an unsupported locale" do
      expect(build(:user, locale: "xx")).not_to be_valid
    end
  end
```

- [ ] **Step 2: Run the specs to verify they fail**

Run: `bundle exec rspec spec/models/user_spec.rb`
Expected: FAIL — `locale` column/attribute doesn't exist yet (`NoMethodError` or `ActiveModel::UnknownAttributeError` from `build(:user, locale: ...)`).

- [ ] **Step 3: Generate and edit the migration**

Run: `bin/rails generate migration AddNameAndLocaleToUsers name:string locale:string`

Edit the generated file (under `db/migrate/`) to read:

```ruby
class AddNameAndLocaleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :locale, :string, null: false, default: "en"
  end
end
```

- [ ] **Step 4: Run the migration**

Run: `bin/rails db:migrate`
Expected: migration applies; `db/schema.rb` gains the two columns and updates its `version:`.

- [ ] **Step 5: Add the model validation**

In `app/models/user.rb`, add the validation after the existing `validates :role, presence: true` line:

```ruby
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
```

- [ ] **Step 6: Run the specs to verify they pass**

Run: `bundle exec rspec spec/models/user_spec.rb`
Expected: PASS (all examples, including the pre-existing ones).

- [ ] **Step 7: Commit**

```bash
git add db/migrate db/schema.rb app/models/user.rb spec/models/user_spec.rb
git commit -m "Add name and locale columns to users"
```

---

### Task 2: Locale follows the signed-in user, not a URL param

**Files:**
- Modify: `app/controllers/application_controller.rb`
- Modify: `spec/requests/locale_spec.rb`
- Modify: `spec/requests/devise_locale_spec.rb`

**Interfaces:**
- Consumes: `User#locale` (Task 1).
- Produces: nothing new consumed by later tasks — `current_user.locale` is set directly in specs via `create(:user, locale: ...)` until Task 3 adds a UI for it.

- [ ] **Step 1: Replace the request-param locale mechanism**

In `app/controllers/application_controller.rb`, replace:

```ruby
  def switch_locale(&action)
    I18n.with_locale(requested_locale, &action)
  end

  # Never hand an unknown locale to I18n: with `enforce_available_locales` on (the
  # default) that raises I18n::InvalidLocale and 500s the request.
  def requested_locale
    valid_locale_param || I18n.default_locale
  end

  def valid_locale_param
    requested = params[:locale].to_s
    requested if I18n.available_locales.map(&:to_s).include?(requested)
  end

  def default_url_options
    { locale: valid_locale_param }
  end
```

with:

```ruby
  def switch_locale(&action)
    I18n.with_locale(current_user&.locale || I18n.default_locale, &action)
  end
```

- [ ] **Step 2: Rewrite `spec/requests/locale_spec.rb`**

Replace its entire contents with:

```ruby
require "rails_helper"

RSpec.describe "Locale switching", type: :request do
  it "renders English by default" do
    sign_in create(:user)
    get clients_path
    expect(response.body).to include("Clients")
  end

  it "renders Portuguese for a user whose locale is pt" do
    sign_in create(:user, locale: "pt")
    get clients_path
    expect(response.body).to include("Clientes")
  end

  it "ignores a ?locale param now that locale is a per-user setting" do
    sign_in create(:user, locale: "pt")
    get clients_path(locale: "en")
    expect(response.body).to include("Clientes")
  end
end
```

- [ ] **Step 3: Rewrite `spec/requests/devise_locale_spec.rb`**

Replace its entire contents with:

```ruby
require "rails_helper"

RSpec.describe "Devise pages before sign-in", type: :request do
  it "renders the sign-in page in English (no current_user yet to read a locale from)" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation missing")
  end

  it "renders an English message for a failed sign-in" do
    post user_session_path, params: { user: { email: "nobody@example.com", password: "wrong" } }

    expect(response.body).to include("Invalid email or password.")
  end

  it "falls back to English rather than rendering 'translation missing'" do
    I18n.with_locale(:pt) do
      # A key that only exists in English (Rails' own error messages are not translated
      # to Portuguese in this app), so it must fall back instead of blowing up.
      expect(I18n.t("errors.messages.blank")).to eq("can't be blank")
      expect(I18n.t("devise.sessions.signed_out")).to eq("Sessão terminada com sucesso.")
    end
  end
end
```

- [ ] **Step 4: Run both specs to verify they pass**

Run: `bundle exec rspec spec/requests/locale_spec.rb spec/requests/devise_locale_spec.rb`
Expected: PASS (all examples).

- [ ] **Step 5: Run the full suite to check for regressions**

Run: `bundle exec rspec`
Expected: PASS (all examples — `default_url_options` no longer injecting `locale:` touches every generated URL app-wide).

- [ ] **Step 6: Commit**

```bash
git add app/controllers/application_controller.rb spec/requests/locale_spec.rb spec/requests/devise_locale_spec.rb
git commit -m "Make locale a per-user preference instead of a URL param"
```

---

### Task 3: Settings page — profile form (name + language)

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/settings_controller.rb`
- Create: `app/views/settings/edit.html.erb`
- Modify: `config/locales/en.yml`
- Modify: `config/locales/pt.yml`
- Test: `spec/requests/settings_spec.rb`

**Interfaces:**
- Produces: route helpers `edit_settings_path` (GET), `settings_path` (PATCH) — Task 4 adds `settings_password_path` into the same controller/view; Task 5 links to `edit_settings_path` from the nav.
- Consumes: `User#name`, `User#locale` (Task 1).

- [ ] **Step 1: Write the failing request specs**

Create `spec/requests/settings_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Settings", type: :request do
  let(:user) { create(:user, name: "Original", locale: "en", password: "password123") }

  before { sign_in user }

  it "updates the profile name and locale" do
    patch settings_path, params: { user: { name: "Updated Name", locale: "pt" } }

    expect(response).to redirect_to(edit_settings_path)
    user.reload
    expect(user.name).to eq("Updated Name")
    expect(user.locale).to eq("pt")
  end

  it "rejects an invalid locale" do
    patch settings_path, params: { user: { name: "Updated Name", locale: "xx" } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(user.reload.name).not_to eq("Updated Name")
  end
end
```

- [ ] **Step 2: Run the specs to verify they fail**

Run: `bundle exec rspec spec/requests/settings_spec.rb`
Expected: FAIL — `settings_path`/`edit_settings_path` undefined (no route yet).

- [ ] **Step 3: Add the routes**

In `config/routes.rb`, add after `resources :repairs`:

```ruby
  resource :settings, only: %i[edit update]
```

(Task 4 adds the password route on the same line group.)

- [ ] **Step 4: Add the i18n keys**

In `config/locales/en.yml`, add a new top-level `settings:` key after the `parts:` block, before `common:`:

```yaml
  settings:
    title: "Account Settings"
    profile_heading: "Profile"
    fields:
      name: "Name"
      language: "Language"
    languages:
      en: "English"
      pt: "Português"
    save_profile: "Save Profile"
    profile_updated: "Profile updated."
```

In `config/locales/pt.yml`, in the same position:

```yaml
  settings:
    title: "Definições da Conta"
    profile_heading: "Perfil"
    fields:
      name: "Nome"
      language: "Idioma"
    languages:
      en: "English"
      pt: "Português"
    save_profile: "Guardar Perfil"
    profile_updated: "Perfil atualizado."
```

- [ ] **Step 5: Add the controller**

Create `app/controllers/settings_controller.rb`:

```ruby
class SettingsController < ApplicationController
  def edit
  end

  def update
    if current_user.update(settings_params)
      redirect_to edit_settings_path, notice: t("settings.profile_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(:name, :locale)
  end
end
```

- [ ] **Step 6: Add the view**

Create `app/views/settings/edit.html.erb`:

```erb
<%= render "shared/page_head", title: t("settings.title") %>

<div class="max-w-xl space-y-6">
  <div class="card p-6">
    <h2 class="title-display text-2xl mb-4"><%= t("settings.profile_heading") %></h2>

    <% if current_user.errors.include?(:name) || current_user.errors.include?(:locale) %>
      <div class="form-error-box mb-4">
        <ul>
          <% (current_user.errors.full_messages_for(:name) + current_user.errors.full_messages_for(:locale)).each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <%= form_with model: current_user, url: settings_path, method: :patch, class: "space-y-5" do |f| %>
      <div>
        <%= f.label :name, t("settings.fields.name"), class: "field-label" %>
        <%= f.text_field :name, class: "field-input" %>
      </div>

      <div>
        <%= f.label :locale, t("settings.fields.language"), class: "field-label" %>
        <%= f.select :locale, [[t("settings.languages.en"), "en"], [t("settings.languages.pt"), "pt"]], {}, class: "field-input" %>
      </div>

      <%= f.submit t("settings.save_profile"), class: "btn-primary cursor-pointer w-full sm:w-auto" %>
    <% end %>
  </div>
</div>
```

- [ ] **Step 7: Run the specs to verify they pass**

Run: `bundle exec rspec spec/requests/settings_spec.rb`
Expected: PASS (both examples).

- [ ] **Step 8: Commit**

```bash
git add config/routes.rb app/controllers/settings_controller.rb app/views/settings/edit.html.erb config/locales/en.yml config/locales/pt.yml spec/requests/settings_spec.rb
git commit -m "Add settings page with a profile (name + language) form"
```

---

### Task 4: Password change + full system spec

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/controllers/settings_controller.rb`
- Modify: `app/views/settings/edit.html.erb`
- Modify: `config/locales/en.yml`
- Modify: `config/locales/pt.yml`
- Modify: `spec/requests/settings_spec.rb`
- Test: `spec/system/settings_spec.rb`

**Interfaces:**
- Produces: route helper `settings_password_path` (PATCH).
- Consumes: `current_user.update_with_password` (Devise, via `:database_authenticatable` — available without `:registerable`), `bypass_sign_in` (Devise controller helper).

- [ ] **Step 1: Write the failing request specs**

Append to `spec/requests/settings_spec.rb`, inside the existing `RSpec.describe` block, after the last example:

```ruby
  it "changes the password with the correct current password" do
    patch settings_password_path, params: {
      user: { current_password: "password123", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    expect(response).to redirect_to(edit_settings_path)
    expect(user.reload.valid_password?("newpassword456")).to be true
  end

  it "keeps the user signed in after a password change" do
    patch settings_password_path, params: {
      user: { current_password: "password123", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    get edit_settings_path
    expect(response).to have_http_status(:ok)
  end

  it "rejects the wrong current password" do
    patch settings_password_path, params: {
      user: { current_password: "wrong", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(user.reload.valid_password?("newpassword456")).to be false
  end

  it "rejects a blank new password" do
    patch settings_password_path, params: {
      user: { current_password: "password123", password: "", password_confirmation: "" }
    }

    expect(response).to have_http_status(:unprocessable_entity)
  end
```

- [ ] **Step 2: Run the specs to verify they fail**

Run: `bundle exec rspec spec/requests/settings_spec.rb`
Expected: FAIL — `settings_password_path` undefined (no route yet).

- [ ] **Step 3: Add the password route**

In `config/routes.rb`, change:

```ruby
  resource :settings, only: %i[edit update]
```

to:

```ruby
  resource :settings, only: %i[edit update]
  patch "settings/password", to: "settings#update_password", as: "settings_password"
```

- [ ] **Step 4: Add the i18n keys**

In `config/locales/en.yml`, inside the `settings:` block, add after `fields:`'s `language:` line:

```yaml
      current_password: "Current Password"
      new_password: "New Password"
      password_confirmation: "Confirm New Password"
```

and after `save_profile:`/`profile_updated:`:

```yaml
    password_heading: "Change Password"
    save_password: "Change Password"
    password_updated: "Password updated."
```

In `config/locales/pt.yml`, inside the `settings:` block, in the same positions:

```yaml
      current_password: "Palavra-passe Atual"
      new_password: "Nova Palavra-passe"
      password_confirmation: "Confirmar Nova Palavra-passe"
```

```yaml
    password_heading: "Alterar Palavra-passe"
    save_password: "Alterar Palavra-passe"
    password_updated: "Palavra-passe atualizada."
```

- [ ] **Step 5: Add the controller action**

In `app/controllers/settings_controller.rb`, add after `update`:

```ruby
  def update_password
    if password_params[:password].blank?
      current_user.errors.add(:password, :blank)
      render :edit, status: :unprocessable_entity
    elsif current_user.update_with_password(password_params)
      bypass_sign_in(current_user)
      redirect_to edit_settings_path, notice: t("settings.password_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end
```

and add this private method alongside `settings_params`:

```ruby
  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
```

- [ ] **Step 6: Add the password form to the view**

In `app/views/settings/edit.html.erb`, add a second card after the profile card's closing `</div>`, still inside the outer `max-w-xl space-y-6` div:

```erb
  <div class="card p-6">
    <h2 class="title-display text-2xl mb-4"><%= t("settings.password_heading") %></h2>

    <% password_errors = %i[current_password password password_confirmation].flat_map { |attr| current_user.errors.full_messages_for(attr) } %>
    <% if password_errors.any? %>
      <div class="form-error-box mb-4">
        <ul>
          <% password_errors.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <%= form_with model: current_user, url: settings_password_path, method: :patch, class: "space-y-5" do |f| %>
      <div>
        <%= f.label :current_password, t("settings.fields.current_password"), class: "field-label" %>
        <%= f.password_field :current_password, class: "field-input" %>
      </div>

      <div>
        <%= f.label :password, t("settings.fields.new_password"), class: "field-label" %>
        <%= f.password_field :password, class: "field-input" %>
      </div>

      <div>
        <%= f.label :password_confirmation, t("settings.fields.password_confirmation"), class: "field-label" %>
        <%= f.password_field :password_confirmation, class: "field-input" %>
      </div>

      <%= f.submit t("settings.save_password"), class: "btn-primary cursor-pointer w-full sm:w-auto" %>
    <% end %>
  </div>
```

- [ ] **Step 7: Run the request specs to verify they pass**

Run: `bundle exec rspec spec/requests/settings_spec.rb`
Expected: PASS (all 6 examples).

- [ ] **Step 8: Write the system spec**

Create `spec/system/settings_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Managing account settings", type: :system do
  let!(:user) { create(:user, email: "manager@example.com", password: "password123", name: "Original Name") }

  before { sign_in user }

  it "updates the profile name and language" do
    visit edit_settings_path

    fill_in "Name", with: "New Name"
    select "Português", from: "Language"
    click_on "Save Profile"

    expect(page).to have_content("Perfil atualizado.")
    expect(page).to have_content("New Name")
  end

  it "changes the password and can sign in with the new one" do
    visit edit_settings_path

    fill_in "Current Password", with: "password123"
    fill_in "New Password", with: "newpassword456"
    fill_in "Confirm New Password", with: "newpassword456"
    click_on "Change Password"

    expect(page).to have_content("Password updated.")

    click_on "Sign out"
    fill_in "Email", with: "manager@example.com"
    fill_in "Password", with: "newpassword456"
    click_on "Log in"

    expect(page).to have_content("Clients")
  end

  it "shows an error for the wrong current password" do
    visit edit_settings_path

    fill_in "Current Password", with: "wrong-password"
    fill_in "New Password", with: "newpassword456"
    fill_in "Confirm New Password", with: "newpassword456"
    click_on "Change Password"

    expect(page).to have_content("is invalid")
  end
end
```

- [ ] **Step 9: Run the system spec to verify it passes**

Run: `bundle exec rspec spec/system/settings_spec.rb`
Expected: PASS (all 3 examples).

- [ ] **Step 10: Run the full suite to check for regressions**

Run: `bundle exec rspec`
Expected: PASS (all examples).

- [ ] **Step 11: Commit**

```bash
git add config/routes.rb app/controllers/settings_controller.rb app/views/settings/edit.html.erb config/locales/en.yml config/locales/pt.yml spec/requests/settings_spec.rb spec/system/settings_spec.rb
git commit -m "Add password change to settings"
```

---

### Task 5: Link the nav identity to settings

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Modify: `spec/requests/clients_spec.rb`

**Interfaces:**
- Consumes: `edit_settings_path` (Task 3), `current_user.name`, `current_user.email`.

- [ ] **Step 1: Write the failing request specs**

Append to `spec/requests/clients_spec.rb`, inside the existing `RSpec.describe` block, after the last example:

```ruby
  it "links the account identity in the nav to the settings page" do
    sign_in create(:user, name: "Ana")
    get clients_path
    expect(response.body).to include(edit_settings_path)
    expect(response.body).to include("Ana")
  end

  it "falls back to email in the nav when the user has no name" do
    user = create(:user, name: nil)
    sign_in user
    get clients_path
    expect(response.body).to include(user.email)
  end
```

- [ ] **Step 2: Run the specs to verify the first one fails**

Run: `bundle exec rspec spec/requests/clients_spec.rb`
Expected: FAIL on "links the account identity..." — the nav has no link to `edit_settings_path` yet. (The fallback-to-email example already passes today since the nav shows the email as plain text — that's expected and fine.)

- [ ] **Step 3: Update the nav**

In `app/views/layouts/application.html.erb`, replace:

```erb
            <span class="hidden sm:inline text-sm font-mono text-gray-400"><%= current_user.email %></span>
```

with:

```erb
            <%= link_to current_user.name.presence || current_user.email, edit_settings_path, class: "hidden sm:inline text-sm font-mono text-gray-400 hover:text-white" %>
```

- [ ] **Step 4: Run the specs to verify they pass**

Run: `bundle exec rspec spec/requests/clients_spec.rb`
Expected: PASS (all examples).

- [ ] **Step 5: Run the full suite to check for regressions**

Run: `bundle exec rspec`
Expected: PASS (all examples — the layout change touches every page).

- [ ] **Step 6: Commit**

```bash
git add app/views/layouts/application.html.erb spec/requests/clients_spec.rb
git commit -m "Link the nav account identity to settings"
```
