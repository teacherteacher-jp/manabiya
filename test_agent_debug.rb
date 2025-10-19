require_relative 'config/environment'

puts "=== AgentLoop Debug Test ==="
puts

# LLMクライアントを作成
claude = Llm::Claude.new

# Discord Botインスタンスを作成
discord_bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))

# より詳細なロガーを作成
logger = Logger.new($stdout)
logger.level = Logger::DEBUG

# AgentLoopを作成
agent = Llm::AgentLoop.new(
  claude,
  discord_bot: discord_bot,
  logger: logger
)

# シンプルなシステムプロンプト
system_prompt = <<~PROMPT
  あなたはTT村のDiscordサーバーのヘルプボットです。
  ユーザーの質問に対して、過去の会話を検索して答えてください。

  検索結果が見つかったら、それをもとに簡潔に答えてください。
  見つからなかったら、「見つかりませんでした」と伝えてください。
PROMPT

# シンプルなテスト
puts "Query: チラシについて教えて"
puts "=" * 80
puts

start_time = Time.now

result = agent.run(
  user_message: "チラシについて教えて",
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
