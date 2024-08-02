class Region < ApplicationRecord
  has_many :member_regions, dependent: :destroy
  has_many :members, through: :member_regions

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
