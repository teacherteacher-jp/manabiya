require_relative 'config/environment'

puts "=== Discord Formatter Bold Display Name Test ==="
puts

# テスト用のモックデータ
mock_author_with_global_name = {
  "id" => "123456789",
  "username" => "john_doe",
  "global_name" => "John Doe",
  "discriminator" => "0"
}

mock_author_without_global_name = {
  "id" => "987654321",
  "username" => "jane_smith",
  "discriminator" => "0"
}

mock_author_nil = nil

puts "Test 1: Author with global_name"
puts "Input: #{mock_author_with_global_name.inspect}"
result = Discord::Formatter.bold_display_name(mock_author_with_global_name)
puts "Output: #{result}"
puts "Expected: **John Doe**"
puts "✓ PASS" if result == "**John Doe**"
puts

puts "Test 2: Author without global_name (using username)"
puts "Input: #{mock_author_without_global_name.inspect}"
result = Discord::Formatter.bold_display_name(mock_author_without_global_name)
puts "Output: #{result}"
puts "Expected: **jane_smith**"
puts "✓ PASS" if result == "**jane_smith**"
puts

puts "Test 3: Nil author"
puts "Input: nil"
result = Discord::Formatter.bold_display_name(mock_author_nil)
puts "Output: #{result}"
puts "Expected: **不明なユーザー**"
puts "✓ PASS" if result == "**不明なユーザー**"
puts

puts "=" * 80
puts "Test 4: format_message_info with bold display name"
puts

mock_message = {
  "id" => "1234567890",
  "channel_id" => "9876543210",
  "author" => mock_author_with_global_name,
  "content" => "これはテストメッセージです",
  "timestamp" => "2025-01-20T10:30:00.000Z"
}

server_id = "1111111111"

result = Discord::Formatter.format_message_info(
  mock_message,
  server_id: server_id,
  include_link: true,
  include_channel: true
)

puts "Result:"
puts result
puts
puts "Expected to contain:"
puts "  - **John Doe** (bold display name)"
puts "  - <#9876543210> (channel mention)"
puts "  - (2025-01-20 XX:XX) (timestamp)"
puts "  - https://discord.com/channels/.../... (message link)"
puts

if result.include?("**John Doe**") &&
   result.include?("<#9876543210>") &&
   result.include?("https://discord.com/channels/")
  puts "✓ PASS - All components present"
else
  puts "✗ FAIL - Missing components"
end

puts
puts "=" * 80
puts "Test 5: Real Discord API integration test"
puts

# Discord Botインスタンスを作成
discord_bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))

# 最近のメッセージを1件取得して表示をテスト
puts "Searching for a recent message..."
result = discord_bot.search_messages_in_server2(
  query: "スケジュール",
  limit: 1
)

if result[:messages].empty?
  puts "No messages found. Skipping API integration test."
else
  message = result[:messages].first

  puts "Found message:"
  puts "  Author username: #{message.dig('author', 'username')}"
  puts "  Author global_name: #{message.dig('author', 'global_name')}"
  puts "  Content: #{message['content']&.slice(0, 50)}..."
  puts

  # bold_display_nameを使ってフォーマット
  formatted_author = Discord::Formatter.bold_display_name(message["author"])
  puts "Formatted author name: #{formatted_author}"
  puts

  # GetThreadContextツールを使って実際のフォーマットを確認
  if message["channel_id"]
    puts "Testing GetThreadContext tool with this channel..."
    tool = Discord::Tools::GetThreadContext.new(discord_bot)
    thread_context = tool.execute({ "thread_id" => message["channel_id"], "limit" => 3 })

    puts "GetThreadContext output (first 500 chars):"
    puts thread_context.slice(0, 500)
    puts

    if thread_context.include?("**")
      puts "✓ PASS - Output contains bold formatting"
    else
      puts "✗ FAIL - Output does not contain bold formatting"
    end
  end
end

puts
puts "=" * 80
puts "All tests completed!"
