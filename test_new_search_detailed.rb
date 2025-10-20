require_relative 'config/environment'

puts "=== New Discord Search API Detailed Test ==="
puts

# Discord Botインスタンスを作成
discord_bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))

# テスト用の検索クエリ
queries = ["チラシ", "Teacher", "勉強会"]

queries.each do |query|
  puts "=" * 80
  puts "Query: #{query}"
  puts "=" * 80

  start_time = Time.now

  result = discord_bot.search_messages_in_server2(
    query: query,
    limit: 10,
    sort_by: "timestamp",
    sort_order: "desc"
  )

  elapsed = Time.now - start_time

  puts "⏱️  Elapsed: #{elapsed.round(2)}s"
  puts "📊 Results: #{result[:messages].size} messages (out of #{result[:total_results]} total)"
  puts

  if result[:error]
    puts "❌ ERROR: #{result[:error]}"
  elsif result[:messages].any?
    result[:messages].take(3).each_with_index do |msg, idx|
      puts "--- Message #{idx + 1} ---"

      # 基本情報
      author = msg.dig("author", "username") || msg.dig("author", "global_name") || "Unknown"
      content = msg["content"]
      timestamp = msg["timestamp"]
      channel_id = msg["channel_id"]

      puts "Author: #{author}"
      puts "Channel ID: #{channel_id}"
      puts "Timestamp: #{timestamp}"

      if content.present?
        # コンテンツを表示（最初の150文字）
        display_content = content.length > 150 ? content[0..150] + "..." : content
        puts "Content: #{display_content}"
      elsif msg["embeds"].present?
        # embedsの場合
        embed = msg["embeds"].first
        puts "Embed: #{embed["title"]&.slice(0, 100) || embed["description"]&.slice(0, 100)}"
      else
        puts "Content: (empty or attachment only)"
      end

      puts
    end
  else
    puts "No results found"
  end

  puts
  sleep 0.5  # レート制限対策
end

puts "=" * 80
puts "All tests completed!"
puts "=" * 80
