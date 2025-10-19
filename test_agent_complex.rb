#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== Complex AgentLoop Test ==="
puts ""

claude = Llm::Claude.new
agent = Llm::AgentLoop.new(claude)

result = agent.run(
  user_message: "今日の日付と時刻を教えて。あと、125 * 8 の計算もお願い！",
  system_prompt: "ツールを使って正確な情報を提供してください。複数のツールを使う必要がある場合は、適切に使い分けてください。"
)

puts ""
puts "=== Final Result ==="
puts result
puts ""
puts "Iterations: #{agent.iterations}"
puts "Total tokens: #{agent.total_tokens}"
