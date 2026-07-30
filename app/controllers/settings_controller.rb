class SettingsController < ApplicationController
  def edit
  end

  def update
    if current_user.update(settings_params)
      # The locale may have just changed as part of this update, but this request
      # started with the old one — re-localize the flash so it isn't left behind
      # in the language the user is switching away from.
      notice = I18n.with_locale(current_user.locale) { t("settings.profile_updated") }
      redirect_to edit_settings_path, notice: notice
    else
      render :edit, status: :unprocessable_entity
    end
  end

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

  private

  def settings_params
    params.require(:user).permit(:name, :locale)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
