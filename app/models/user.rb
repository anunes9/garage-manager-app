class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  enum :role, { admin: 0, garage_manager: 1 }

  validates :role, presence: true
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }

  # Ransack (used by ActiveAdmin's index filters) requires an explicit allowlist of
  # searchable attributes. Sensitive columns (encrypted_password, reset_password_token)
  # are intentionally excluded.
  def self.ransackable_attributes(auth_object = nil)
    %w[id name email role created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
