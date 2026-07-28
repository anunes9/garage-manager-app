# Account Settings — Design

## Purpose

Let a signed-in user change their own display name, language, and password
from a self-service settings page, separate from the admin-only User
management in ActiveAdmin (which continues to own email/role).

## Data model

Two new columns on `users`:

- `name` (string, nullable) — no presence validation. Existing seeded users
  have no name today; forcing one on them isn't part of this feature, so the
  column stays optional and the nav falls back to email when blank.
- `locale` (string, default `"en"` at the DB level) — validated on the model
  with `validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }`
  so a bad value can never reach `I18n.with_locale` and raise.

## Locale mechanism change (replaces the `?locale=` param)

Today `ApplicationController` has:

- `switch_locale` (around_action) wrapping the request in `I18n.with_locale(requested_locale)`
- `requested_locale` / `valid_locale_param`, which read and validate `params[:locale]`
- `default_url_options` returning `{ locale: valid_locale_param }` so every
  generated URL in a request carries the current locale forward

All of this is replaced by:

```ruby
around_action :switch_locale

def switch_locale(&action)
  I18n.with_locale(current_user&.locale || I18n.default_locale, &action)
end
```

`default_url_options`, `requested_locale`, and `valid_locale_param` are deleted.

**Consequence, explicitly accepted:** pages reachable before sign-in (the
login form, a failed-login flash) have no `current_user`, so they always
render in English now. There is no longer a way to preview them in
Portuguese via a URL param. `authenticate_user!` already exempts Devise's
own controllers (`devise_controller?` short-circuits it — confirmed via
`Devise::SessionsController._process_action_callbacks`), so this is purely
about losing the language *preview* capability pre-login, not an access
regression.

Two existing spec files test the old mechanism directly and are rewritten
rather than deleted:

- `spec/requests/locale_spec.rb` — becomes: locale follows `current_user.locale`
  (English when unset, Portuguese when set to `"pt"`), and a `?locale=` param
  is now inert (ignored).
- `spec/requests/devise_locale_spec.rb` — the "?locale=pt on the login page"
  examples are replaced with "the login page always renders in English
  (no current_user yet)"; the fallback-to-English-without-blowing-up
  coverage for missing translation keys is kept as-is, since that's still a
  real safety net independent of how the locale gets set.

## Settings page

New `SettingsController`, routed as:

```ruby
resource :settings, only: %i[edit update]
patch "settings/password", to: "settings#update_password", as: "settings_password"
```

`edit` renders one page with **two independent forms**:

1. **Profile form** (name + language) — `PATCH /settings` →
   `current_user.update(settings_params)`. No current password required:
   changing your display name or language is not a security-sensitive action.
2. **Password form** (current password, new password, confirmation) —
   `PATCH /settings/password` → `current_user.update_with_password(...)`,
   Devise's built-in method that validates `current_password` before
   applying the change and adds a `current_password` error otherwise.
   After a successful password change the controller re-signs the user in
   (`bypass_sign_in(current_user)`) — changing the password changes the
   session-validating salt, which would otherwise silently sign them out.

Both forms redirect back to `edit_settings_path` with a flash notice on
success, or re-render the page with inline errors on failure (same pattern
`CarsController`/`ClientsController` already use).

Rejected alternative: enabling Devise's `:registerable` module and using its
stock `RegistrationsController`. That gives combined profile+password editing
for free, but requires `current_password` for *every* field (including just
changing your display name — worse UX), and it also brings in self-service
sign-up routes this app doesn't want, since users are provisioned via
ActiveAdmin only.

## Nav integration

The nav currently shows `current_user.email` as plain text next to "Sign out".
It becomes a link to `edit_settings_path`, displaying `current_user.name`
when present, falling back to `current_user.email` otherwise.

## i18n

New keys in both `config/locales/en.yml` and `config/locales/pt.yml` under a
`settings:` namespace: page title, field labels (name, language, current
password, new password, password confirmation), the language `<select>`'s
option labels ("English"/"Português"), and success messages for the two forms
("Profile updated." / "Password updated."). Devise's built-in
`current_password` error message is already covered by its existing
locale files.

## Out of scope

- No email change (stays admin-only via ActiveAdmin).
- No account deletion / self-service sign-up (no `:registerable`).
- No "remember me" or session-management UI.
- No avatar/profile picture.

## Testing

- Model spec: `locale` inclusion validation (valid locales pass, `"xx"` fails).
- Request specs: profile update (name + locale change, and that the locale
  change is actually reflected in the next request's rendered text);
  password update (correct current password succeeds and the user stays
  signed in; wrong current password fails with an error and doesn't change
  the password).
- Rewritten `locale_spec.rb` / `devise_locale_spec.rb` per above.
- System spec: sign in, visit settings, change name and language, change
  password, verify the new password works on next sign-in.
