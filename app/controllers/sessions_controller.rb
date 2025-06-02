class SessionsController < ApplicationController
  skip_before_action :redirect_to_gate_unless_logged_in

  def create
    auth_hash = request.env["omniauth.auth"]
    pp auth_hash

    token = auth_hash.dig("credentials", "token")
    servers = Discord::User.new(token).servers
    server = servers.find { |s| s["id"] == Rails.application.credentials.dig("discord", "server_id") }
    pp servers

    if server
      uid = auth_hash.dig("uid")

      required_role_ids = Rails.application.credentials.dig("discord", "required_role_ids")

      if required_role_ids && required_role_ids.count > 0
        bot = Discord::Bot.new(Rails.application.credentials.dig("discord_app", "bot_token"))
        member_info = bot.server_member(uid)
        pp member_info

        unless member_info
          redirect_to gate_path, alert: "メンバー情報の取得に失敗しました。再度お試しください。"
          return
        end

        roles = member_info["roles"] || []
        unless required_role_ids.any? { roles.include?(it) }
          redirect_to gate_path, alert: "必要なロールが付与されていません。管理者にお問い合わせください。"
          return
        end
      end

      name = auth_hash.dig("info", "name")
      icon_url = auth_hash.dig("info", "image")
      global_name = auth_hash.dig("extra", "raw_info", "global_name")

      member = Member.find_or_initialize_by(discord_uid: uid)
      member.name = global_name || name
      member.icon_url = icon_url
      member.save

      log_in(member)

      redirect_to root_path
    else
      redirect_to gate_path, alert: "当該Discordサーバへの参加が確認できませんでした"
    end
  end

  def destroy
    log_out
    redirect_to root_path, notice: "ログアウトしました"
  end
end
