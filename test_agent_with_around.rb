require_relative 'config/environment'

puts "=== AgentLoop Test with GetMessagesAround ==="
puts

# LLMクライアントを作成
claude = Llm::Claude.new

# Discord Botインスタンスを作成
discord_bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))

# AgentLoopを作成
agent = Llm::AgentLoop.new(
  claude,
  discord_bot: discord_bot,
  logger: Rails.logger
)

# システムプロンプト
system_prompt = <<~PROMPT
  あなたはTT村（Teacher Teacherのオンラインコミュニティ）のDiscordサーバーのヘルプボットです。

  ユーザーの質問に対して、Discordサーバー内の過去の会話を検索して適切な情報を提供してください。

  【重要】検索と調査の方針:
  1. まず、ユーザーの質問から適切なキーワードで検索する
  2. 検索結果で質問を見つけた場合:
     - そのメッセージのchannel_idとidを確認する
     - `get_messages_around`ツールで前後のメッセージを取得する
     - 前後のメッセージに回答があれば、それを提供する
  3. 検索結果が見つからない場合:
     - 別のキーワードで1-2回まで再検索を試みる
     - それでも見つからなければ「見つかりませんでした」と伝える

  回答は親しみやすく、わかりやすい日本語で行ってください。
  検索は必要最小限に抑え、効率的に情報を提供することを心がけてください。
PROMPT

# テスト
puts "Query: TTのチラシのデータはどこにありますか？"
puts "=" * 80
puts

start_time = Time.now

result = agent.run(
  user_message: "TTのチラシのデータはどこにありますか？",
  system_prompt: system_prompt
)

elapsed = Time.now - start_time

puts
puts "=" * 80
puts "Result:"
puts "=" * 80
puts result
puts
puts "⏱️  Time: #{elapsed.round(2)}s"
puts "🔄 Iterations: #{agent.iterations}"
puts "🎫 Total tokens: #{agent.total_tokens}"
