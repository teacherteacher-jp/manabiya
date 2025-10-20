require_relative 'config/environment'

puts "=== Category-Based Authorization Test ==="
puts

# LLMクライアントを作成
claude = Llm::Claude.new

# Discord Botインスタンスを作成
discord_bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))

# テストするカテゴリID
category_id = "1168552463050231911"

puts "Testing with category restriction: #{category_id}"
puts

# カテゴリ内のチャンネル数を確認
all_channels = discord_bot.get_all_channels
category_channels = all_channels.select { |ch| ch["parent_id"] == category_id }
puts "Category contains #{category_channels.size} channels:"
category_channels.each do |ch|
  puts "  - #{ch['name']} (#{ch['id']}, type: #{ch['type']})"
end
puts

# AgentLoopを作成（カテゴリ制限あり）
agent = Llm::AgentLoop.new(
  claude,
  discord_bot: discord_bot,
  logger: Rails.logger,
  allowed_category_id: category_id
)

# システムプロンプト
system_prompt = <<~PROMPT
  あなたはTT村（Teacher Teacherのオンラインコミュニティ）のDiscordサーバーのヘルプボットです。
  ユーザーからの質問に対して、Discordサーバー内の過去の会話を検索して適切な情報を提供してください。

  回答する際の注意点:
  - 簡潔で分かりやすい日本語で答えてください
  - 検索は必要最小限に抑え、効率的に情報を提供することを心がけてください
  - 親しみやすい口調で回答してください
PROMPT

# テスト
puts "=" * 80
puts "Query: 明太子について教えて"
puts "=" * 80
puts

start_time = Time.now

result = agent.run(
  user_message: "明太子について教えて",
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
puts

puts "=" * 80
puts "Authorization test completed!"
puts "The agent should only search within category #{category_id}"
puts "=" * 80
