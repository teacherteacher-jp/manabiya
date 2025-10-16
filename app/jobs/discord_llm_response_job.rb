class DiscordLlmResponseJob < ApplicationJob
  queue_as :default

  # @param channel_id [String] Discord チャンネルID
  # @param thread_id [String] Discord スレッドID
  # @param user_message [String] ユーザーのメッセージ
  # @param user_name [String] ユーザー名
  def perform(channel_id:, thread_id:, user_message:, user_name:)
    Rails.logger.info "DiscordLlmResponseJob started for thread: #{thread_id}"

    # 会話履歴を構築
    messages = build_conversation_history(thread_id, user_message)

    # LLMで応答を生成
    llm = create_llm_provider
    response_text = llm.generate(
      messages: messages,
      system_prompt: system_prompt,
      temperature: 0.7,
      max_tokens: 2048
    )

    # Discordに返信
    send_to_discord(thread_id, response_text)

    Rails.logger.info "DiscordLlmResponseJob completed for thread: #{thread_id}"
  rescue StandardError => e
    Rails.logger.error "DiscordLlmResponseJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # エラー時もDiscordに通知
    send_to_discord(thread_id, "申し訳ございません。エラーが発生しました。しばらく待ってから再度お試しください。")
    raise
  end

  private

  # LLMプロバイダーのインスタンスを作成
  # 環境変数やcredentialsで切り替え可能にする
  def create_llm_provider
    provider = Rails.application.credentials.dig(:llm, :provider) || "claude"

    case provider.to_sym
    when :claude
      Llm::Claude.new
    else
      raise ArgumentError, "Unsupported LLM provider: #{provider}"
    end
  end

  # 会話履歴を構築
  # 本実装では簡略化して最新のメッセージのみ
  # 将来的にはDiscordスレッドから過去の会話を取得して履歴を構築
  def build_conversation_history(thread_id, user_message)
    # TODO: Discordスレッドから過去のメッセージを取得して履歴を構築
    [
      { role: "user", content: user_message }
    ]
  end

  # システムプロンプト
  def system_prompt
    <<~PROMPT
      あなたはTeacher Teacherのオンラインコミュニティ「TT村」のヘルプボットです。
      ユーザーからの質問に丁寧に答えてください。

      回答する際の注意点:
      - 簡潔で分かりやすい日本語で答えてください
      - 不確かなことは推測せず、分からないと正直に答えてください
      - 必要に応じて、追加の情報を求めてください
    PROMPT
  end

  # Discordにメッセージを送信
  def send_to_discord(thread_id, message)
    bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))
    bot.send_message(
      channel_or_thread_id: thread_id,
      content: message
    )
  rescue => e
    Rails.logger.error "Failed to send message to Discord: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
