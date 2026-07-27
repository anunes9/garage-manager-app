class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  enum :role, { admin: 0, garage_manager: 1 }

  validates :role, presence: true

  # Ransack (used by ActiveAdmin's index filters) requires an explicit allowlist of
  # searchable attributes. Sensitive columns (encrypted_password, reset_password_token)
  # are intentionally excluded.
  def self.ransackable_attributes(auth_object = nil)
    %w[id email role created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
