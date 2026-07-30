# ActiveAdmin ships its stylesheet as SCSS, which Propshaft cannot compile on its own.
# Only build ActiveAdmin's own stylesheet here (the default "application.scss" build
# target added by the dartsass-rails installer is unused by this app, which relies on
# tailwindcss-rails for its own styling, so it is dropped to keep the builds directory free
# of dead output).
Rails.application.config.dartsass.builds = { "active_admin.scss" => "active_admin.css" }
