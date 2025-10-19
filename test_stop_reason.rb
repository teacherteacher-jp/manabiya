#!/usr/bin/env ruby
require_relative 'config/environment'

claude = Llm::Claude.new
response = claude.messages_with_tools(
  messages: [{role: "user", content: "今の時刻を教えて"}],
  system: "ツールを使ってください",
  tools: [Tools::GetCurrentTime.definition],
  max_tokens: 500
)

puts "stop_reason class: #{response.stop_reason.class}"
puts "stop_reason value: #{response.stop_reason.inspect}"
puts "Comparison with 'tool_use' (string): #{response.stop_reason == 'tool_use'}"
puts "Comparison with :tool_use (symbol): #{response.stop_reason == :tool_use}"
