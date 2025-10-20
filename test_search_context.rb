require_relative 'config/environment'
require 'net/http'
require 'json'
require 'uri'

puts "=== Guild Search API Context Test ==="
puts

token = Rails.application.credentials.dig(:discord_app, :bot_token)
server_id = Rails.application.credentials.dig(:discord, :server_id)

# APIを直接呼び出し
query = "チラシ、どこ"
uri = URI("https://discord.com/api/v10/guilds/#{server_id}/messages/search?content=#{URI.encode_www_form_component(query)}&limit=2")
request = Net::HTTP::Get.new(uri)
request['Authorization'] = "Bot #{token}"

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end

if response.code == "200"
  data = JSON.parse(response.body)

  puts "Total results: #{data['total_results']}"
  puts "Message groups returned: #{data['messages']&.size || 0}"
  puts

  if data['messages'] && data['messages'].any?
    puts "=== First Message Group ==="
    first_group = data['messages'].first

    puts "Number of messages in this group: #{first_group.size}"
    puts

    first_group.each_with_index do |msg, idx|
      puts "--- Message #{idx + 1} in group ---"
      puts "ID: #{msg['id']}"
      puts "Author: #{msg.dig('author', 'username')}"
      puts "Content: #{msg['content']&.slice(0, 100)}"
      puts "Timestamp: #{msg['timestamp']}"
      puts "Hit: #{msg['hit'] ? 'YES (this is the matching message)' : 'no (context message)'}"
      puts
    end

    puts "=== Analysis ==="
    puts "Messages with 'hit' flag: #{first_group.count { |m| m['hit'] }}"
    puts "Context messages (no 'hit' flag): #{first_group.count { |m| !m['hit'] }}"
  else
    puts "No results found"
  end
else
  puts "Error: #{response.code}"
  puts response.body
end
