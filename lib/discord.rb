module Discord
  BASE_URL = "https://discord.com"
  BASE_PATH = "/api/v10"

  class User
    def initialize(user_token)
      @connection = Faraday.new(
      url: BASE_URL,
      headers: {
        "Authorization" => "Bearer #{user_token}",
        "Content-Type" => "application/json"
        }
      )
    end

    def servers
      JSON.parse(get("/users/@me/guilds").body)
    end

    def get(path)
      @connection.get(BASE_PATH + path)
    end
  end

  class Bot
    def initialize(bot_token)
      @connection = Faraday.new(
        url: BASE_URL,
        headers: {
          "Authorization" => "Bot #{bot_token}",
          "Content-Type" => "application/json"
        }
      )
    end

    def send_message(channel_or_thread_id:, content: nil, embeds: nil, allowed_mentions: nil)
      response = @connection.post("#{BASE_PATH}/channels/#{channel_or_thread_id}/messages") do |req|
        req.body = { content:, embeds:, allowed_mentions: }.to_json
      end
      JSON.parse(response.body)
    end

    def server_member(member_id)
      response = get("/guilds/#{server_id}/members/#{member_id}")

      if response.status == 200
        JSON.parse(response.body)
      else
        Rails.logger.error "Failed to get server member: #{response.status} - #{response.body}"
      end
    end

    def invitations
      JSON.parse(get("/guilds/#{server_id}/invites").body)
    end

    def get(path)
      @connection.get(BASE_PATH + path)
    end

    def server_id
      Rails.application.credentials.dig("discord", "server_id")
    end
  end
end
