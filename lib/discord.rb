require 'securerandom'
require 'net/http'
require 'json'

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
      @bot_token = bot_token
      @connection = Faraday.new(
        url: BASE_URL,
        headers: {
          "Authorization" => "Bot #{bot_token}",
          "Content-Type" => "application/json"
        }
      )
    end

    def send_message(channel_or_thread_id:, content: nil, embeds: nil, allowed_mentions: nil, files: nil)
      if files.present?
        # ファイルがある場合はNet::HTTPでmultipart/form-dataを送信
        send_message_with_files(
          channel_or_thread_id: channel_or_thread_id,
          content: content,
          embeds: embeds,
          allowed_mentions: allowed_mentions,
          files: files
        )
      else
        # ファイルがない場合は従来通りJSONで送信
        response = @connection.post("#{BASE_PATH}/channels/#{channel_or_thread_id}/messages") do |req|
          req.body = { content:, embeds:, allowed_mentions: }.to_json
        end
        JSON.parse(response.body)
      end
    end

    private

    def send_message_with_files(channel_or_thread_id:, content:, embeds:, allowed_mentions:, files:)
      uri = URI("#{BASE_URL}#{BASE_PATH}/channels/#{channel_or_thread_id}/messages")

      boundary = SecureRandom.hex(16)

      # StringIOを使ってバイナリセーフな本文を組み立てる
      body = StringIO.new
      body.binmode

      # payload_jsonパート
      payload_json = { content:, embeds:, allowed_mentions: }.compact.to_json
      body.write("--#{boundary}\r\n".force_encoding(Encoding::BINARY))
      body.write("Content-Disposition: form-data; name=\"payload_json\"\r\n".force_encoding(Encoding::BINARY))
      body.write("Content-Type: application/json\r\n\r\n".force_encoding(Encoding::BINARY))
      body.write(payload_json.force_encoding(Encoding::BINARY))
      body.write("\r\n".force_encoding(Encoding::BINARY))

      # ファイルパート
      files.each_with_index do |file, index|
        body.write("--#{boundary}\r\n".force_encoding(Encoding::BINARY))
        body.write("Content-Disposition: form-data; name=\"files[#{index}]\"; filename=\"#{file.original_filename}\"\r\n".force_encoding(Encoding::BINARY))
        body.write("Content-Type: #{file.content_type}\r\n\r\n".force_encoding(Encoding::BINARY))
        body.write(file.read.force_encoding(Encoding::BINARY))
        body.write("\r\n".force_encoding(Encoding::BINARY))
        file.rewind
      end

      body.write("--#{boundary}--\r\n".force_encoding(Encoding::BINARY))

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bot #{@bot_token}"
      request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
      request.body = body.string

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      JSON.parse(response.body)
    end

    public

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
