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
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    { locale: params[:locale] }
  end

  def authenticate_admin_user!
    authenticate_user!
    redirect_to root_path, alert: t("common.not_authorized") unless current_user.admin?
  end
end
