#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== AgentLoop Test ==="
puts ""

claude = Llm::Claude.new
discord_bot = Discord::Bot.new(Rails.application.credentials.dig(:discord_app, :bot_token))
agent = Llm::AgentLoop.new(claude, discord_bot: discord_bot, logger: Rails.logger)

result = agent.run(
  user_message: "今の時刻を教えて",
  system_prompt: "ツールを使って正確な情報を提供してください"
)

puts ""
puts "=== Final Result ==="
puts result
puts ""
puts "Iterations: #{agent.iterations}"
puts "Total tokens: #{agent.total_tokens}"
