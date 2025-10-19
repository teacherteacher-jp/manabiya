class DiscordLlmResponseJob < ApplicationJob
  queue_as :default

  # @param channel_id [String] Discord チャンネルID
  # @param thread_id [String] Discord スレッドID
  # @param user_message [String] ユーザーのメッセージ
  # @param user_name [String] ユーザー名
  def perform(channel_id:, thread_id:, user_message:, user_name:)
    Rails.logger.info "DiscordLlmResponseJob started for thread: #{thread_id}"

    # LLMクライアントとDiscord Botを作成
    claude = create_llm_provider
    discord_bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))

    # チャンネルのカテゴリIDを取得（認可制御用）
    category_id = discord_bot.get_channel_category(channel_id)
    if category_id
      Rails.logger.info "Restricting agent to category: #{category_id}"
    else
      Rails.logger.info "No category restriction (channel has no category)"
    end

    # AgentLoopを作成
    agent = Llm::AgentLoop.new(
      claude,
      discord_bot: discord_bot,
      logger: Rails.logger,
      allowed_category_id: category_id
    )

    # AgentLoopで応答を生成
    response_text = agent.run(
      user_message: user_message,
      system_prompt: system_prompt
    )

    # Discordに返信
    send_to_discord(thread_id, response_text)

    Rails.logger.info "DiscordLlmResponseJob completed for thread: #{thread_id}"
    Rails.logger.info "Agent stats - Iterations: #{agent.iterations}, Tokens: #{agent.total_tokens}"
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

  # システムプロンプト
  def system_prompt
    <<~PROMPT
      あなたはTeacher Teacherのオンラインコミュニティ「TT村」のDiscordサーバーのヘルプボットです。
      ユーザーからの質問に対して、Discordサーバー内の過去の会話を検索して適切な情報を提供してください。

      【重要】検索と調査の方針:
      1. まず、ユーザーの質問から適切なキーワードで検索する
      2. 検索結果で関連する質問や情報を見つけた場合:
         - そのメッセージのchannel_idとidを確認する
         - `get_messages_around`ツールで前後のメッセージを取得する
         - 前後のメッセージに回答があれば、それを提供する
      3. 検索結果が見つからない場合:
         - 別のキーワードで1-2回まで再検索を試みる
         - それでも見つからなければ「見つかりませんでした」と伝える

      回答する際の注意点:
      - 簡潔で分かりやすい日本語で答えてください
      - 不確かなことは推測せず、分からないと正直に答えてください
      - 検索は必要最小限に抑え、効率的に情報を提供することを心がけてください
      - 親しみやすい口調で回答してください
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
