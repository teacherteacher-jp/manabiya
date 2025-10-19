module Tools
  class GetCurrentTime
    # Anthropic Tool Use API形式の定義
    def self.definition
      {
        name: "get_current_time",
        description: "現在の日時を取得します。タイムゾーンを指定できます。",
        input_schema: {
          type: "object",
          properties: {
            timezone: {
              type: "string",
              description: "タイムゾーン (例: 'Asia/Tokyo', 'UTC', 'America/New_York')",
              default: "Asia/Tokyo"
            },
            format: {
              type: "string",
              description: "日時のフォーマット (例: 'full' は詳細、'short' は簡易)",
              enum: ["full", "short"],
              default: "full"
            }
          },
          required: []
        }
      }
    end

    # ツールを実行
    # @param input [Hash] ツールへの入力
    # @return [String] 現在時刻
    def self.execute(input)
      timezone = input["timezone"] || input[:timezone] || "Asia/Tokyo"
      format_type = input["format"] || input[:format] || "full"

      begin
        time = Time.now.in_time_zone(timezone)

        if format_type == "short"
          "現在時刻: #{time.strftime('%Y-%m-%d %H:%M:%S')}"
        else
          "現在時刻: #{time.strftime('%Y年%m月%d日 %H時%M分%S秒')} (#{timezone})"
        end
      rescue => e
        "エラー: #{e.message}"
      end
    end
  end
end
