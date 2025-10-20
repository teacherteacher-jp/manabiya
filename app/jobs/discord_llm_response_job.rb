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

    # スレッド内の会話履歴を取得
    thread_context = build_thread_context(discord_bot, thread_id, user_message)

    # スレッドコンテキストを含めたメッセージを構築
    full_message = if thread_context.present?
      <<~MESSAGE.strip
        【このスレッドでのこれまでの会話】
        #{thread_context}

        【最新の質問】
        #{user_message}
      MESSAGE
    else
      user_message
    end

    Rails.logger.info "Thread context included: #{thread_context.present?}"

    # 進捗通知用のコールバック
    on_progress = ->(message) {
      send_to_discord(thread_id, message)
    }

    # AgentLoopを作成
    agent = Llm::AgentLoop.new(
      claude,
      discord_bot: discord_bot,
      logger: Rails.logger,
      allowed_category_id: category_id,
      on_progress: on_progress
    )

    # AgentLoopで応答を生成
    response_text = agent.run(
      user_message: full_message,
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

      【重要】Discord検索が必要かどうかの判断:
      - TT村固有の情報（イベント、メンバー、過去の会話、コミュニティのルールなど）が必要な質問
        → Discordを検索してください
      - プログラミングや一般常識など、あなたの知識だけで答えられる質問
        → 検索せずに直接答えてください
      - 判断に迷う場合
        → Discordを検索してください（念のため確認する方が安全です）

      【Discord検索が必要な場合の方針】:
      1. ユーザーの質問から適切なキーワードで search_discord_messages を使用
      2. 検索結果で関連する情報を見つけた場合:
         - そのメッセージのchannel_idとidを確認
         - get_messages_around ツールで前後のメッセージを取得
         - 前後のメッセージに回答があれば、それを提供
      3. 検索結果が見つからない場合:
         - 別のキーワードで1-2回まで再検索を試みる
         - それでも見つからなければ「見つかりませんでした」と伝える

      【回答する際の注意点】:
      - 簡潔で分かりやすい日本語で答えてください
      - 不確かなことは推測せず、分からないと正直に答えてください
      - 検索は必要最小限に抑え、効率的に情報を提供することを心がけてください
      - 親しみやすい口調で回答してください

      【重要】検索結果の引用について:
      - 検索結果にはユーザーメンション（<@USER_ID>）とメッセージリンク（https://discord.com/channels/...）が含まれています
      - 回答でユーザーの発言を引用する際は、必ずこれらのメンションとリンクをそのまま使用してください
      - 例: 「<@123456789>さんが[こちらのメッセージ](https://discord.com/channels/...)で...」のように
      - これによりユーザーは発言者や元の会話に簡単にアクセスできます
    PROMPT
  end

  # スレッド内の会話履歴からコンテキストを構築
  # @param discord_bot [Discord::Bot] Discordボットインスタンス
  # @param thread_id [String] スレッドID
  # @param current_message [String] 現在のユーザーメッセージ
  # @return [String, nil] フォーマットされた会話履歴（履歴がない場合はnil）
  def build_thread_context(discord_bot, thread_id, current_message)
    # スレッドの直近20件のメッセージを取得
    messages = discord_bot.get_thread_messages(thread_id, limit: 20)

    # ボット自身のIDを取得（ボットのメッセージを識別するため）
    bot_user_id = Rails.application.credentials.dig(:discord_app, :bot_user_id)

    # 会話履歴を構築
    # - 最新のユーザーメッセージ（現在の質問）は除外
    # - 直近10件程度に絞る
    recent_messages = messages
      .reject { |m| m["content"] == current_message } # 現在のメッセージを除外
      .last(10) # 直近10件

    # メッセージが1件以下（現在のメッセージしかない）場合はコンテキストなし
    return nil if recent_messages.empty?

    # フォーマット
    recent_messages.map do |msg|
      author_id = msg.dig("author", "id")
      author_name = msg.dig("author", "username") || msg.dig("author", "global_name") || "不明"
      content = msg["content"] || ""

      # ボットのメッセージか判定
      is_bot = author_id == bot_user_id || msg.dig("author", "bot") == true

      if is_bot
        "ボット: #{content.slice(0, 200)}" # ボットの応答は200文字まで
      else
        "#{author_name}: #{content.slice(0, 200)}" # ユーザーのメッセージも200文字まで
      end
    end.join("\n")
  rescue => e
    Rails.logger.error "Failed to build thread context: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil # エラー時はコンテキストなしで続行
  end

  # Discordにメッセージを送信
  def send_to_discord(thread_id, message)
    bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))
    bot.send_message(
      channel_or_thread_id: thread_id,
      content: message,
      allowed_mentions: { parse: [] } # メンションを表示するが通知は送らない
    )
  rescue => e
    Rails.logger.error "Failed to send message to Discord: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
