#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== Discord Search Test (General Keywords) ==="
puts ""

claude = Llm::Claude.new
agent = Llm::AgentLoop.new(claude)

# より一般的なキーワードで検索
result = agent.run(
  user_message: "Discordで最近「Rails」について話している人はいますか？",
  system_prompt: <<~PROMPT
    あなたはTeacher Teacherコミュニティ「TT村」のDiscordサポートアシスタントです。
    ユーザーの質問に答えるため、必要に応じてツールを使って情報を収集してください。

    検索結果が見つかった場合は、誰がどんな話をしているか簡潔に要約してください。
    見つからなかった場合は、その旨を伝えてください。
  PROMPT
)

puts ""
puts "=== Final Result ==="
puts result
puts ""
puts "Iterations: #{agent.iterations}"
puts "Total tokens: #{agent.total_tokens}"
