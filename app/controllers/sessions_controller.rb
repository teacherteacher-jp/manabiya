class SessionsController < ApplicationController
  def create
    auth_hash = request.env["omniauth.auth"]
    pp auth_hash

    token = auth_hash.dig("credentials", "token")
    servers = Discord.new(token).servers
    server = servers.find { |s| s["id"] == Rails.application.credentials.dig("discord", "server_id") }
    pp servers

    if server
      uid = auth_hash.dig("uid")
      name = auth_hash.dig("info", "name")
      icon_url = auth_hash.dig("info", "image")
      global_name = auth_hash.dig("extra", "raw_info", "global_name")

      member = Member.find_or_initialize_by(discord_uid: uid)
      member.name = global_name ||name
      member.icon_url = icon_url
      member.save

      log_in(member)

      redirect_to root_path
    else
      redirect_to root_path, alert: "Teacher TeacherのDiscordサーバに参加している人のみ利用できます"
    end
  end

  def destroy
    log_out
    redirect_to root_path, notice: "ログアウトしました"
  end
end
