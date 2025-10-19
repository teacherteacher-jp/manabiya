module Discord
  module Tools
    class GetChannelInfo
      def initialize(bot)
        @bot = bot
      end

      # Anthropic Tool Use API形式の定義
      def self.definition
        {
          name: "get_channel_info",
          description: "Discordチャンネルの情報を取得します。チャンネル名、トピック、カテゴリなどの情報が得られます。",
          input_schema: {
            type: "object",
            properties: {
              channel_id: {
                type: "string",
                description: "チャンネルID"
              }
            },
            required: ["channel_id"]
          }
        }
      end

      # AgentLoopから呼び出されるインスタンスメソッド
      def definition
        self.class.definition
      end

      # ツールの実行（インスタンスメソッド）
      # @param input [Hash] ツールへの入力
      # @return [String] チャンネル情報
      def execute(input)
        channel_id = input["channel_id"] || input[:channel_id]

        channel = @bot.get_channel(channel_id)

        unless channel
          return "チャンネルID「#{channel_id}」の情報が見つかりませんでした。"
        end

        format_channel_info(channel)
      rescue => e
        Rails.logger.error "GetChannelInfo failed: #{e.class} - #{e.message}"
        "チャンネル情報の取得中にエラーが発生しました: #{e.message}"
      end

      private

      # チャンネル情報をフォーマット
      # @param channel [Hash] チャンネル情報
      # @return [String] フォーマットされた情報
      def self.format_channel_info(channel)
        info = []
        info << "【チャンネル情報】"
        info << "名前: #{channel['name']}"
        info << "タイプ: #{channel_type(channel['type'])}"

        if channel['topic'].present?
          info << "トピック: #{channel['topic']}"
        end

        if channel['parent_id']
          info << "カテゴリID: #{channel['parent_id']}"
        end

        info.join("\n")
      end

      # チャンネルタイプを人間が読める形式に変換
      # @param type [Integer] チャンネルタイプ
      # @return [String] タイプ名
      def self.channel_type(type)
        case type
        when 0 then "テキストチャンネル"
        when 2 then "ボイスチャンネル"
        when 4 then "カテゴリ"
        when 5 then "アナウンスチャンネル"
        when 11 then "パブリックスレッド"
        when 12 then "プライベートスレッド"
        when 15 then "フォーラムチャンネル"
        else "不明(#{type})"
        end
      end
    end
  end
end
