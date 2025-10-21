module Tools
  class WebSearch
    # Anthropic Tool Use API形式の定義
    def self.definition
      {
        name: "web_search",
        description: "インターネット上の最新情報を検索します。ニュース、技術情報、一般的な質問への回答などを取得できます。",
        input_schema: {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "検索クエリ"
            },
            count: {
              type: "integer",
              description: "取得する検索結果の数 (1-20, デフォルト: 5)",
              default: 5
            }
          },
          required: ["query"]
        }
      }
    end

    # AgentLoopから呼び出されるインスタンスメソッド
    def definition
      self.class.definition
    end

    # ツールを実行（インスタンスメソッド）
    # @param input [Hash] ツールへの入力
    # @return [String] 検索結果
    def execute(input)
      query = input["query"] || input[:query]
      count = input["count"] || input[:count] || 5
      count = [[count, 1].max, 20].min # 1-20の範囲に制限

      # Brave Search APIを呼び出し
      result = search_with_brave(query, count)
      result
    rescue => e
      Rails.logger.error "WebSearch failed: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      "検索エラー: #{e.message}"
    end

    private

    # Brave Search APIで検索
    # @param query [String] 検索クエリ
    # @param count [Integer] 取得する結果数
    # @return [String] 検索結果
    def search_with_brave(query, count)
      require "faraday"
      require "json"

      api_key = Rails.application.credentials.dig(:brave_search_api, :api_key)
      raise "Brave Search API key is not configured" if api_key.blank?

      conn = Faraday.new(url: "https://api.search.brave.com") do |f|
        f.response :json
        f.adapter Faraday.default_adapter
      end

      response = conn.get("/res/v1/web/search") do |req|
        req.headers["Accept"] = "application/json"
        req.headers["X-Subscription-Token"] = api_key
        req.params["q"] = query
        req.params["count"] = count
      end

      if response.success?
        data = response.body
        format_results(data)
      else
        error_message = response.body.is_a?(Hash) ? response.body["message"] : response.body
        "検索エラー: #{response.status} - #{error_message}"
      end
    end

    # 検索結果をフォーマット
    # @param data [Hash] Brave APIのレスポンス
    # @return [String] フォーマットされた検索結果
    def format_results(data)
      web_results = data.dig("web", "results") || []

      if web_results.empty?
        return "検索結果が見つかりませんでした。"
      end

      result = "🔍 検索結果 (#{web_results.size}件):\n\n"

      web_results.each_with_index do |item, i|
        result += "#{i + 1}. **#{item['title']}**\n"
        result += "   #{item['description']}\n" if item["description"]
        result += "   🔗 #{item['url']}\n"

        # ページの公開日時があれば表示
        if item["age"]
          result += "   📅 #{item['age']}\n"
        end

        result += "\n"
      end

      # FAQsがあれば追加
      if data.dig("faq", "results")&.any?
        result += "\n📚 関連FAQ:\n"
        data["faq"]["results"].first(3).each do |faq|
          result += "Q: #{faq['question']}\n"
          result += "A: #{faq['answer']}\n\n"
        end
      end

      result
    end
  end
end
