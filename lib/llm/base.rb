module Llm
  class Base
    # LLMプロバイダーの抽象基底クラス
    # 各プロバイダーはこのクラスを継承して実装する

    # @param messages [Array<Hash>] 会話履歴の配列
    #   例: [{ role: "user", content: "こんにちは" }, { role: "assistant", content: "はい、こんにちは" }]
    # @param system_prompt [String] システムプロンプト
    # @param temperature [Float] 生成のランダム性 (0.0 ~ 1.0)
    # @param max_tokens [Integer] 生成する最大トークン数
    # @return [String] LLMからの応答テキスト
    def generate(messages:, system_prompt: nil, temperature: 0.7, max_tokens: 1024)
      raise NotImplementedError, "#{self.class}#generate must be implemented"
    end

    # プロバイダー名を返す
    # @return [Symbol] プロバイダー名 (例: :claude, :openai, :gemini)
    def provider_name
      raise NotImplementedError, "#{self.class}#provider_name must be implemented"
    end

    protected

    # メッセージ履歴のバリデーション
    # @param messages [Array<Hash>] 会話履歴
    # @raise [ArgumentError] メッセージ形式が不正な場合
    def validate_messages!(messages)
      raise ArgumentError, "messages must be an Array" unless messages.is_a?(Array)

      messages.each do |msg|
        raise ArgumentError, "each message must be a Hash" unless msg.is_a?(Hash)
        raise ArgumentError, "each message must have :role" unless msg.key?(:role)
        raise ArgumentError, "each message must have :content" unless msg.key?(:content)
        raise ArgumentError, "role must be 'user' or 'assistant'" unless %w[user assistant].include?(msg[:role].to_s)
      end
    end
  end
end
