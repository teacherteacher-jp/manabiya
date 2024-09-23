class Member < ApplicationRecord
  has_many :schedules, dependent: :destroy
  has_many :assignments, through: :schedules
  has_many :member_regions, dependent: :destroy
  has_many :regions, through: :member_regions

  validates :discord_uid, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 32 }
  validates :icon_url, presence: true, length: { maximum: 2083 }

  after_save :fill_server_joined_at

  def fill_server_joined_at
    return if server_joined_at

    bot = Discord::Bot.new(Rails.application.credentials.dig("discord_app", "bot_token"))
    server_member = bot.server_member(discord_uid)
    self.update_columns(server_joined_at: server_member.dig("joined_at"))
  end
end
