require_relative 'config/environment'

puts "=== Discord Bot Integration Test ==="
puts "Testing DiscordLlmResponseJob with AgentLoop"
puts

# テストケース
test_cases = [
  {
    name: "チラシのデータ場所の質問",
    user_message: "TTのチラシのデータはどこにありますか？",
    description: "get_messages_aroundツールを使って前後の会話から回答を探す"
  },
  {
    name: "勉強会についての質問",
    user_message: "最近の勉強会について教えて",
    description: "検索ツールで情報を見つけて整理する"
  },
  {
    name: "シンプルな質問",
    user_message: "TT村について教えて",
    description: "基本的な情報提供"
  }
]

# ダミーのチャンネルIDとスレッドID
# 実際にはDiscordから取得されますが、テストでは適当な値を使用
dummy_channel_id = "1261928341183664158"  # 実際のテストチャンネル
dummy_thread_id = "test_thread_#{Time.now.to_i}"

test_cases.each_with_index do |test_case, idx|
  puts "=" * 80
  puts "Test Case #{idx + 1}: #{test_case[:name]}"
  puts "Description: #{test_case[:description]}"
  puts "User Message: #{test_case[:user_message]}"
  puts "=" * 80
  puts

  begin
    start_time = Time.now

    # Jobを実行（performを直接呼び出す）
    job = DiscordLlmResponseJob.new

    # send_to_discordメソッドをモックして実際の送信をスキップ
    def job.send_to_discord(thread_id, message)
      puts "📤 [MOCK] Would send to Discord thread #{thread_id}:"
      puts "─" * 40
      puts message
      puts "─" * 40
      puts
    end

    job.perform(
      channel_id: dummy_channel_id,
      thread_id: dummy_thread_id,
      user_message: test_case[:user_message],
      user_name: "test_user"
    )

    elapsed = Time.now - start_time

    puts "✅ Test completed successfully"
    puts "⏱️  Time: #{elapsed.round(2)}s"
    puts

  rescue => e
    puts "❌ Test failed with error:"
    puts "   #{e.class}: #{e.message}"
    puts "   #{e.backtrace.first(5).join("\n   ")}"
    puts
  end

  # 次のテストの前に少し待つ
  sleep 2 if idx < test_cases.size - 1
end

puts "=" * 80
puts "All integration tests completed!"
puts "=" * 80
