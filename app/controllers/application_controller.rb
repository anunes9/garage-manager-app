class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  around_action :switch_locale

  def after_sign_in_path_for(resource)
    clients_path
  end

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

  def authenticate_admin_user!
    authenticate_user!
    redirect_to root_path, alert: t("common.not_authorized") unless current_user.admin?
  end
end
