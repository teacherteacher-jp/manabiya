class OpenaiClient
  def initialize(api_key:)
    raise ArgumentError, "API key is required" if api_key.blank?
    @api_key = api_key
    @client = ::OpenAI::Client.new(access_token: @api_key)
  end

  def chat(system_message:, user_message:, options: {})
    raise ArgumentError, "System message cannot be blank" if system_message.blank?
    raise ArgumentError, "User message cannot be blank" if user_message.blank?

    begin
      response = @client.chat(
        parameters: {
          model: options[:model] || "gpt-4o-mini",
          messages: build_messages(system_message, user_message),
          max_tokens: options[:max_tokens] || 1000,
          temperature: options[:temperature] || 0.7
        }
      )

      extract_content_from_response(response)
    rescue => e
      Rails.logger.error "OpenAI API Error: #{e.message}"
      raise StandardError, "OpenAI API呼び出し中にエラーが発生しました: #{e.message}"
    end
  end

  def api_key_configured?
    @api_key.present?
  end

  private

  def build_messages(system_message, user_message)
    [
      {
        role: "system",
        content: system_message
      },
      {
        role: "user",
        content: user_message
      }
    ]
  end

  def extract_content_from_response(response)
    if response.dig("choices", 0, "message", "content")
      response["choices"][0]["message"]["content"].strip
    else
      raise StandardError, "予期しないAPIレスポンス形式です"
    end
  end
end
