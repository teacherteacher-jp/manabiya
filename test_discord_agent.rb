#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== Discord Agent Test ==="
puts ""
puts "このテストでは、Claudeが自律的にDiscordのメッセージを検索します。"
puts ""

claude = Llm::Claude.new
agent = Llm::AgentLoop.new(claude)

# Discord検索のテスト
result = agent.run(
  user_message: "Discordで「TTのチラシ」について話している人を探して",
  system_prompt: <<~PROMPT
    あなたはTeacher Teacherコミュニティ「TT村」のDiscordサポートアシスタントです。
    ユーザーの質問に答えるため、必要に応じてツールを使って情報を収集してください。

    利用可能なツール:
    - search_discord_messages: Discord内の過去のメッセージを検索
    - get_channel_info: チャンネル情報を取得
    - get_thread_context: スレッド内の会話履歴を取得
    - calculator: 計算を実行
    - get_current_time: 現在時刻を取得

    検索結果が見つかった場合は、その内容を要約して回答してください。
    見つからなかった場合は、その旨を伝えてください。
  PROMPT
)

puts ""
puts "=== Final Result ==="
puts result
puts ""
puts "Iterations: #{agent.iterations}"
puts "Total tokens: #{agent.total_tokens}"
