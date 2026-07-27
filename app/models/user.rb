class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  enum :role, { admin: 0, garage_manager: 1 }

  validates :role, presence: true
end
