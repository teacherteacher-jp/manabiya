class DiscordLlmResponseJob < ApplicationJob
  queue_as :default

  # @param channel_id [String] Discord チャンネルID
  # @param thread_id [String] Discord スレッドID
  # @param user_message [String] ユーザーのメッセージ
  # @param user_name [String] ユーザー名
  def perform(channel_id:, thread_id:, user_message:, user_name:)
    Rails.logger.info "DiscordLlmResponseJob started for thread: #{thread_id}"

    # Discord過去メッセージを検索してコンテキスト構築
    context = search_and_build_context(user_message, channel_id)

    # 会話履歴を構築
    messages = build_conversation_history(thread_id, user_message)

    # LLMで応答を生成
    llm = create_llm_provider
    response_text = llm.generate(
      messages: messages,
      system_prompt: system_prompt_with_context(context),
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

  # Discord過去メッセージを検索してコンテキスト構築
  def search_and_build_context(user_message, channel_id)
    return nil if user_message.blank?

    # Claudeに検索キーワードを抽出してもらう
    search_query = extract_search_keywords(user_message)

    return nil if search_query.blank?

    Rails.logger.info "Original message: #{user_message}"
    Rails.logger.info "Extracted search keywords: #{search_query}"

    bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))

    # メンションされたチャンネルのカテゴリを取得
    category_id = bot.get_channel_category(channel_id)

    if category_id
      Rails.logger.info "Current channel category: #{category_id}"
      Rails.logger.info "Searching within same category only"
    else
      Rails.logger.info "Channel has no category, searching across entire server"
    end

    # 同じカテゴリ内で検索 (カテゴリがない場合はサーバー全体)
    results = bot.search_messages_in_server(
      query: search_query,
      limit: 30,
      max_results: 5,
      category_id: category_id
    )

    return nil if results.empty?

    Rails.logger.info "Found #{results.size} relevant messages across server"

    # 検索結果の内容をログ出力
    results.each_with_index do |msg, index|
      author = msg.dig("author", "username") || "Unknown"
      content_preview = msg["content"]&.slice(0, 100) || ""
      timestamp = Time.parse(msg["timestamp"]).strftime("%Y-%m-%d %H:%M")

      Rails.logger.info "  [#{index + 1}] #{timestamp} #{author}: #{content_preview}"
    end

    # 結果をフォーマット
    format_search_results(results)
  rescue => e
    Rails.logger.error "Failed to search Discord messages: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  # Claudeに検索キーワードを抽出してもらう
  def extract_search_keywords(user_message)
    llm = create_llm_provider

    prompt = <<~PROMPT
      以下のユーザーメッセージから、Discord過去発言を検索するための
      最も重要なキーワードを1つだけ抽出してください。

      ルール:
      - 最も重要で特徴的な名詞や固有名詞を1つ選ぶ
      - 一般的すぎる単語(例: Google, 情報)は避ける
      - 助詞や助動詞は除外
      - キーワード1つのみを出力
      - 余計な説明は不要

      例:
      入力: "マイクチェックについて教えて"
      出力: マイクチェック

      入力: "Railsのエラーで困っています"
      出力: Rails

      入力: "Googleの「Gemini」について話している人はいますか？"
      出力: Gemini

      ユーザーメッセージ: #{user_message}
    PROMPT

    keywords = llm.generate(
      messages: [{ role: "user", content: prompt }],
      system_prompt: "あなたは検索クエリ抽出の専門家です。指示に従って最も重要なキーワード1つのみを出力してください。",
      temperature: 0.3,
      max_tokens: 50
    )

    # 余計な改行や空白を削除
    keywords.strip
  rescue => e
    Rails.logger.error "Failed to extract search keywords: #{e.message}"
    # エラー時は元のメッセージをそのまま使用
    user_message
  end

  # 検索結果をClaudeに渡す形式にフォーマット
  def format_search_results(results)
    formatted = results.map do |msg|
      timestamp = Time.parse(msg["timestamp"]).strftime("%Y-%m-%d %H:%M")
      author = msg.dig("author", "username") || "Unknown"
      content = msg["content"]

      "#{timestamp} #{author}: #{content}"
    end.join("\n\n")

    <<~CONTEXT
      参考情報として、Discordサーバー内の関連する過去発言を以下に示します:

      #{formatted}
    CONTEXT
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

  # コンテキスト付きシステムプロンプト
  def system_prompt_with_context(context)
    base = system_prompt
    return base unless context

    <<~PROMPT
      #{base}

      #{context}

      上記の参考情報を考慮して、ユーザーの質問に答えてください。
      ただし、参考情報が質問と関連性が低い場合は無視してください。
      参考情報を使う場合は、自然な形で引用しながら答えてください。
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
