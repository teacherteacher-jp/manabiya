require 'securerandom'
require 'net/http'
require 'json'
require 'uri'

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

    # 特定のチャンネル情報を取得
    # @param channel_id [String] チャンネルID
    # @return [Hash, nil] チャンネル情報
    def get_channel(channel_id)
      response = get("/channels/#{channel_id}")

      return nil unless response.status == 200

      JSON.parse(response.body)
    rescue => e
      Rails.logger.error "Failed to get channel #{channel_id}: #{e.message}"
      nil
    end

    # サーバー内の全チャンネルを取得
    # @return [Array<Hash>] チャンネル情報の配列
    def get_all_channels
      response = get("/guilds/#{server_id}/channels")

      return [] unless response.status == 200

      channels = JSON.parse(response.body)

      # テキストチャンネル (type: 0) とフォーラムチャンネル (type: 15) をフィルタ
      channels.select { |ch| [0, 15].include?(ch["type"]) }
    rescue => e
      Rails.logger.error "Failed to get channels: #{e.message}"
      []
    end

    # 特定カテゴリに属するチャンネルを取得
    # @param category_id [String] カテゴリID
    # @return [Array<Hash>] チャンネル情報の配列
    def get_channels_in_category(category_id)
      all_channels = get_all_channels

      all_channels.select { |ch| ch["parent_id"] == category_id }
    end

    # Forumチャンネルの全スレッド一覧を取得（アクティブ + アーカイブ）
    # @param forum_channel_id [String] ForumチャンネルID
    # @return [Array<Hash>] スレッド情報の配列
    def get_all_threads_in_forum(forum_channel_id)
      all_threads = []

      # アクティブなスレッドを取得
      active_response = get("/channels/#{forum_channel_id}/threads/active")
      if active_response.status == 200
        active_data = JSON.parse(active_response.body)
        all_threads.concat(active_data["threads"] || [])
      end

      # アーカイブされたスレッドを取得
      archived_response = get("/channels/#{forum_channel_id}/threads/archived/public")
      if archived_response.status == 200
        archived_data = JSON.parse(archived_response.body)
        all_threads.concat(archived_data["threads"] || [])
      end

      all_threads
    rescue => e
      Rails.logger.error "Failed to get threads in forum #{forum_channel_id}: #{e.message}"
      []
    end

    # チャンネルの属するカテゴリIDを取得
    # @param channel_id [String] チャンネルID
    # @return [String, nil] カテゴリID
    def get_channel_category(channel_id)
      channel = get_channel(channel_id)
      return nil unless channel

      # スレッドの場合 (type == 11 または 12)、parent_idは親チャンネルを指す
      # 通常チャンネルの場合、parent_idはカテゴリを指す
      if [11, 12].include?(channel["type"])
        # スレッドの場合: 親チャンネルのカテゴリを取得
        parent_channel_id = channel["parent_id"]
        return nil unless parent_channel_id

        parent_channel = get_channel(parent_channel_id)
        parent_channel&.dig("parent_id")
      else
        # 通常チャンネルの場合: そのままparent_idがカテゴリ
        channel["parent_id"]
      end
    end

    # チャンネルから過去メッセージを取得して検索
    # @param channel_id [String] チャンネルID
    # @param query [String] 検索キーワード
    # @param limit [Integer] 取得するメッセージ数の上限
    # @return [Array<Hash>] メッセージの配列
    def search_messages(channel_id:, query:, limit: 100)
      response = get("/channels/#{channel_id}/messages?limit=#{limit}")

      return [] unless response.status == 200

      messages = JSON.parse(response.body)
      query_lower = query.downcase

      messages.select do |msg|
        content_lower = msg["content"]&.downcase
        content_lower&.include?(query_lower)
      end
    rescue => e
      Rails.logger.error "Failed to search messages in channel #{channel_id}: #{e.message}"
      []
    end

    # 複数チャンネルから検索
    # @param channel_ids [Array<String>] チャンネルIDの配列
    # @param query [String] 検索キーワード
    # @param limit [Integer] 1チャンネルあたりの取得数
    # @param max_results [Integer] 最終的に返す最大件数
    # @return [Array<Hash>] メッセージの配列 (新しい順)
    def search_messages_in_channels(channel_ids:, query:, limit: 50, max_results: 10)
      all_results = []

      channel_ids.each do |channel_id|
        results = search_messages(channel_id: channel_id, query: query, limit: limit)
        all_results.concat(results)
      end

      # 新しい順にソートして上限まで取得
      all_results
        .sort_by { |msg| -Time.parse(msg["timestamp"]).to_i }
        .take(max_results)
    end

    # サーバー全体から検索
    # @param query [String] 検索キーワード
    # @param limit [Integer] 1チャンネルあたりの取得数
    # @param max_results [Integer] 最終的に返す最大件数
    # @param category_id [String, nil] カテゴリIDで絞り込み (nilの場合は全体検索)
    # @return [Array<Hash>] メッセージの配列 (新しい順)
    def search_messages_in_server(query:, limit: 30, max_results: 10, category_id: nil)
      all_channels = get_all_channels

      if category_id
        all_channels = all_channels.select { |ch| ch["parent_id"] == category_id }
        Rails.logger.info "Filtering channels by category: #{category_id}"
      end

      # Forumチャンネルと通常チャンネルを分離
      forum_channels = all_channels.select { |ch| ch["type"] == 15 }
      text_channels = all_channels.select { |ch| ch["type"] == 0 }

      # 検索対象のチャンネルID一覧を作成
      channel_ids = text_channels.map { |ch| ch["id"] }

      # Forumチャンネルの全スレッド（アクティブ + アーカイブ）も追加
      forum_channels.each do |forum|
        threads = get_all_threads_in_forum(forum["id"])
        thread_ids = threads.map { |t| t["id"] }
        channel_ids.concat(thread_ids)
      end

      Rails.logger.info "Searching in #{channel_ids.size} channels/threads (#{text_channels.size} text channels, #{forum_channels.size} forums) for query: #{query}"

      search_messages_in_channels(
        channel_ids: channel_ids,
        query: query,
        limit: limit,
        max_results: max_results
      )
    end

    # サーバー全体から検索 (新しいGuild Search APIを使用)
    # @param query [String] 検索キーワード
    # @param limit [Integer] 最大取得件数 (1-25)
    # @param channel_ids [Array<String>, nil] 検索対象チャンネルIDの配列 (最大500件)
    # @param author_ids [Array<String>, nil] 投稿者IDの配列でフィルタ
    # @param sort_by [String] ソート方法 ("timestamp" or "relevancy")
    # @param sort_order [String] ソート順 ("asc" or "desc")
    # @param offset [Integer] オフセット (0-9975)
    # @return [Hash] { messages: Array<Hash>, total_results: Integer }
    def search_messages_in_server2(
      query:,
      limit: 25,
      channel_ids: nil,
      author_ids: nil,
      sort_by: "timestamp",
      sort_order: "desc",
      offset: 0
    )
      # パラメータ構築
      params = {
        content: query,
        limit: [limit, 25].min,  # 最大25
        sort_by: sort_by,
        sort_order: sort_order,
        offset: offset
      }

      # channel_idsが指定されている場合
      if channel_ids.present?
        # 最大500件まで
        params[:channel_id] = channel_ids.take(500)
      end

      # author_idsが指定されている場合
      if author_ids.present?
        params[:author_id] = author_ids
      end

      # クエリ文字列を構築
      query_string = params.map do |key, value|
        if value.is_a?(Array)
          value.map { |v| "#{key}=#{URI.encode_www_form_component(v.to_s)}" }.join("&")
        else
          "#{key}=#{URI.encode_www_form_component(value.to_s)}"
        end
      end.join("&")

      # APIリクエスト
      path = "/guilds/#{server_id}/messages/search?#{query_string}"
      response = get(path)

      if response.status == 200
        result = JSON.parse(response.body)

        # messagesは配列の配列（各要素は会話のコンテキストを含む）
        # フラット化して、実際のメッセージのみを返す
        messages = result["messages"] || []
        flattened_messages = messages.flatten(1)

        {
          messages: flattened_messages,
          total_results: result["total_results"] || 0,
          analytics_id: result["analytics_id"],
          threads: result["threads"],
          members: result["members"]
        }
      elsif response.status == 202
        # 検索インデックスが準備中
        Rails.logger.warn "Search index not ready (202 response)"
        { messages: [], total_results: 0, error: "Search index not ready" }
      else
        Rails.logger.error "Guild search failed: #{response.status} - #{response.body}"
        { messages: [], total_results: 0, error: "API error: #{response.status}" }
      end
    rescue => e
      Rails.logger.error "Failed to search messages in guild: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { messages: [], total_results: 0, error: e.message }
    end

    # 特定メッセージの前後のメッセージを取得
    # @param channel_id [String] チャンネルID
    # @param message_id [String] 基準となるメッセージID
    # @param limit [Integer] 取得件数（1-100）
    # @return [Array<Hash>] メッセージの配列
    def get_messages_around(channel_id:, message_id:, limit: 10)
      # limitを1-100の範囲に制限
      limit = [[limit, 1].max, 100].min

      path = "/channels/#{channel_id}/messages?around=#{message_id}&limit=#{limit}"
      response = get(path)

      if response.status == 200
        JSON.parse(response.body)
      else
        Rails.logger.error "Get messages around failed: #{response.status} - #{response.body}"
        []
      end
    rescue => e
      Rails.logger.error "Failed to get messages around: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      []
    end
  end
end
