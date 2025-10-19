require_relative 'config/environment'

puts "=== Find Answered Questions Test ==="
puts

discord_bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))

# 複数のキーワードで検索
queries = ["チラシ どこ", "チラシ 印刷", "チラシ データ", "フライヤー"]

queries.each do |query|
  puts "Searching: #{query}"

  result = discord_bot.search_messages_in_server2(
    query: query,
    limit: 5
  )

  result[:messages].each do |msg|
    # 質問っぽいメッセージ（「？」で終わる、または「どこ」「教えて」を含む）
    content = msg["content"] || ""

    if content.include?("？") || content.include?("どこ") || content.include?("教えて")
      puts "  Found potential question:"
      puts "    Channel: #{msg['channel_id']}"
      puts "    Message ID: #{msg['id']}"
      puts "    Author: #{msg.dig('author', 'username')}"
      puts "    Content: #{content.slice(0, 80)}..."

      # 前後のメッセージを確認
      around = discord_bot.get_messages_around(
        channel_id: msg['channel_id'],
        message_id: msg['id'],
        limit: 6
      )

      sorted = around.sort_by { |m| Time.parse(m["timestamp"]) }
      target_idx = sorted.index { |m| m['id'] == msg['id'] }

      # 質問の後のメッセージを確認
      if target_idx && target_idx < sorted.size - 1
        after_messages = sorted[(target_idx + 1)..-1]
        puts "    After messages: #{after_messages.size}"

        after_messages.take(2).each do |after_msg|
          puts "      - #{after_msg.dig('author', 'username')}: #{after_msg['content']&.slice(0, 60)}..."
        end
      end

      puts
    end
  end

  puts
end
