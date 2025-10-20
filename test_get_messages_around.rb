require_relative 'config/environment'

puts "=== Get Messages Around Test ==="
puts

# Discord Botインスタンスを作成
discord_bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))

# まず「チラシ、どこ」で検索して基準メッセージを見つける
puts "Step 1: Search for 'チラシ、どこ'"
result = discord_bot.search_messages_in_server2(
  query: "チラシ、どこ",
  limit: 1
)

if result[:messages].empty?
  puts "No messages found"
  exit
end

first_message = result[:messages].first
channel_id = first_message["channel_id"]
message_id = first_message["id"]

puts "Found message:"
puts "  ID: #{message_id}"
puts "  Channel: #{channel_id}"
puts "  Author: #{first_message.dig('author', 'username')}"
puts "  Content: #{first_message['content']&.slice(0, 100)}"
puts

# Step 2: この メッセージの前後を取得
puts "Step 2: Get messages around this message"
puts

around_messages = discord_bot.get_messages_around(
  channel_id: channel_id,
  message_id: message_id,
  limit: 10
)

puts "Retrieved #{around_messages.size} messages"
puts

# タイムスタンプでソート
sorted = around_messages.sort_by { |m| Time.parse(m["timestamp"]) }

sorted.each_with_index do |msg, idx|
  is_target = msg["id"] == message_id
  marker = is_target ? " ★★★ [THIS IS THE SEARCH RESULT] ★★★" : ""

  puts "--- Message #{idx + 1}#{marker} ---"
  puts "Author: #{msg.dig('author', 'username')}"
  puts "Time: #{msg['timestamp']}"
  puts "Content: #{msg['content']&.slice(0, 200)}"
  puts
end

puts "=" * 80
puts "Analysis:"
puts "Total messages: #{around_messages.size}"
puts "Messages before target: #{sorted.index { |m| m['id'] == message_id }}"
puts "Messages after target: #{sorted.size - sorted.index { |m| m['id'] == message_id } - 1}"
