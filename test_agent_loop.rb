#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== AgentLoop Test ==="
puts ""

claude = Llm::Claude.new
agent = Llm::AgentLoop.new(claude)

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
