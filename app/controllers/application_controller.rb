class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  around_action :switch_locale

  def switch_locale(&action)
    I18n.with_locale(current_user&.locale || I18n.default_locale, &action)
  end

  def authenticate_admin_user!
    authenticate_user!
    redirect_to root_path, alert: t("common.not_authorized") unless current_user.admin?
  end
end
