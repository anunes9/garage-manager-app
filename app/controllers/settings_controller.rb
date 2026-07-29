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
