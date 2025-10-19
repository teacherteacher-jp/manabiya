require_relative 'config/environment'

puts "=== AgentLoop Test with New Search API ==="
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

  【重要】検索の方針:
  1. まず、ユーザーの質問から適切なキーワードを抽出して検索する
  2. 検索結果が見つかった場合:
     - 見つかった情報をもとに、わかりやすく回答する
     - 複数の関連情報がある場合は整理して提示する
  3. 検索結果が見つからなかった場合:
     - 別のキーワード（単語分解、類義語など）で1-2回まで再検索を試みる
     - それでも見つからなければ「見つかりませんでした」と伝える

  回答は親しみやすく、わかりやすい日本語で行ってください。
  検索は必要最小限に抑え、効率的に情報を提供することを心がけてください。
PROMPT

# テストケース
test_cases = [
  {
    query: "わたしは近畿地方在住なんですが、近くの人と話せるようなチャンネルはあるでしょうか？",
    description: "近畿地方に関する検索"
  },
  # {
  #   query: "TTを紹介するためのチラシのデータがどこかにあった気がするのですが、探してほしいです",
  #   description: "チラシに関する検索（リトライテスト）"
  # },
  # {
  #   query: "最近の勉強会について教えて",
  #   description: "勉強会に関する検索"
  # }
]

test_cases.each_with_index do |test_case, idx|
  puts "=" * 80
  puts "Test Case #{idx + 1}: #{test_case[:description]}"
  puts "Query: #{test_case[:query]}"
  puts "=" * 80
  puts

  start_time = Time.now

  result = agent.run(
    user_message: test_case[:query],
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
  puts

  # 次のテストケースの前に少し待つ
  sleep 2 if idx < test_cases.size - 1
end

puts "=" * 80
puts "All tests completed!"
puts "=" * 80
