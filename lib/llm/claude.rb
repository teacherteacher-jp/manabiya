require "anthropic"

module Llm
  class Claude < Base
    MODEL = "claude-sonnet-4-5-20250929"

    def initialize(api_key: nil)
      @api_key = api_key || Rails.application.credentials.dig(:anthropic, :api_key)
      raise ArgumentError, "Anthropic API key is not configured" if @api_key.blank?

      @client = Anthropic::Client.new(api_key: @api_key)
    end

    # @param messages [Array<Hash>] 会話履歴の配列
    # @param system_prompt [String] システムプロンプト
    # @param temperature [Float] 生成のランダム性 (0.0 ~ 1.0)
    # @param max_tokens [Integer] 生成する最大トークン数
    # @return [String] Claudeからの応答テキスト
    def generate(messages:, system_prompt: nil, temperature: 0.7, max_tokens: 1024)
      validate_messages!(messages)

      params = {
        model: MODEL,
        messages: messages.map { |msg| { role: msg[:role].to_s, content: msg[:content] } },
        temperature: temperature,
        max_tokens: max_tokens
      }

      params[:system] = system_prompt if system_prompt.present?

      response = @client.messages.create(**params)

      # Anthropic APIのレスポンス構造からテキストを抽出
      extract_text_from_response(response)
    rescue Faraday::Error => e
      Rails.logger.error("Claude API error: #{e.message}")
      raise StandardError, "Claude API request failed: #{e.message}"
    end

    # Tool Use対応版のメッセージ生成
    # @param messages [Array<Hash>] 会話履歴の配列
    # @param system [String] システムプロンプト
    # @param tools [Array<Hash>] ツール定義の配列
    # @param max_tokens [Integer] 生成する最大トークン数
    # @param temperature [Float] 生成のランダム性 (0.0 ~ 1.0)
    # @return [Anthropic::Models::Message] Anthropic APIのレスポンスオブジェクト
    def messages_with_tools(messages:, system:, tools: [], max_tokens: 4096, temperature: 0.7)
      params = {
        model: MODEL,
        messages: normalize_messages(messages),
        max_tokens: max_tokens,
        temperature: temperature
      }

      params[:system] = system if system.present?
      params[:tools] = tools if tools.present?

      response = @client.messages.create(**params)

      Rails.logger.info "Claude API response: stop_reason=#{response.stop_reason}, usage=#{response.usage.inspect}"

      response
    rescue Faraday::Error => e
      Rails.logger.error("Claude API error: #{e.message}")
      raise StandardError, "Claude API request failed: #{e.message}"
    end

    def provider_name
      :claude
    end

    private

    # メッセージを正規化（Anthropic API形式に変換）
    # @param messages [Array<Hash>] 会話履歴
    # @return [Array<Hash>] 正規化されたメッセージ
    def normalize_messages(messages)
      messages.map do |msg|
        {
          role: msg[:role].to_s,
          content: msg[:content]
        }
      end
    end

    # APIレスポンスからテキストコンテンツを抽出
    # @param response [Anthropic::Models::Message] Anthropic APIのレスポンス
    # @return [String] 抽出されたテキスト
    def extract_text_from_response(response)
      # responseはAnthropic::Models::Messageオブジェクト
      # contentプロパティにアクセス
      content = response.content
      return "" unless content.is_a?(Array)

      # content配列から全てのtext typeのブロックを結合
      # typeはシンボル(:text)で返ってくる
      content
        .select { |block| block.type == :text }
        .map { |block| block.text }
        .join("\n")
    end
  end
end
