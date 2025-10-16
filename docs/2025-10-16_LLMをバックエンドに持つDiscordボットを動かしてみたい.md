# Manabiya Claude Discord Bot 設計書

作成日: 2025-10-16

## プロジェクト概要

### 目的
Manabiyaコミュニティ向けに、Claudeをバックエンドに持つDiscord AIヘルプボットを構築する。

### 実現したい機能
1. Discord Gateway方式でメッセージをリアルタイム受信
2. ボットへのメンション検知
3. スレッドを自動作成して応答
4. Discord会話履歴の参照
5. RAG: Manabiya内の知見データベースを参照

## システムアーキテクチャ

### 全体フロー

```
Discord → Gateway Bot → Rails Job → Claude API → Discord
```

### 技術選定

- Discord Gateway: discordrb gem
- Claude API: anthropic gem
- ジョブキュー: Solid Queue
- データベース: PostgreSQL

## データモデル

### Knowledge (知見データベース)

```ruby
class Knowledge < ApplicationRecord
  belongs_to :member
  validates :title, :content, :category, presence: true

  enum :category, {
    チャンネル情報: 0,
    管理者情報: 1,
    FAQ: 2,
    その他: 3
  }
end
```

## 実装計画

### Phase 0: オウム返しボット (1日) 🎯 **← まずはここから!**
**目標**: メンションされたら、同じ内容をそのまま返すシンプルなボット

**タスク:**
1. ✅ discordrb をGemfileに追加
2. ✅ bundle install
3. ✅ Gateway Botスクリプト作成 (`lib/discord/gateway_bot.rb`, `bin/discord_gateway`)
4. ✅ credentials設定 (discord_app.bot_token)
5. ✅ Procfileにdiscord_gatewayプロセス追加
6. ✅ ローカルでテスト実行

**成果物**: メンションすると「あなたは『○○』と言いました」と返すボット

**実装例:**
```ruby
# lib/discord/gateway_bot.rb
module Discord
  class GatewayBot
    def initialize(token)
      @bot = Discordrb::Bot.new(token: token)
      setup_handlers
    end

    def setup_handlers
      @bot.mention do |event|
        content = event.message.content.gsub(/<@!?\d+>/, "").strip
        event.respond "あなたは「#{content}」と言いました"
      end
    end

    def run
      @bot.run
    end
  end
end
```

---

### Phase 1: LLM統合 (1日) 🎯 **← 現在ここ!**
**目標**: Claudeを組み込んで自然な会話ができるボット

**タスク:**
1. ✅ anthropic gemを追加
2. ✅ LLMプロバイダー抽象化レイヤーの実装
   - `app/services/llm/base.rb`: 基底クラス
   - `app/services/llm/claude.rb`: Claude実装
3. ✅ DiscordLlmResponseJob実装
4. ✅ GatewayBotをジョブキューに接続
5. ⏳ credentials設定 (anthropic.api_key)
6. ⏳ ローカルでテスト実行

**実装完了したファイル:**
- [app/services/llm/base.rb](app/services/llm/base.rb): LLMプロバイダーの抽象インターフェース
- [app/services/llm/claude.rb](app/services/llm/claude.rb): Claude API実装
- [app/jobs/discord_llm_response_job.rb](app/jobs/discord_llm_response_job.rb): Discord応答ジョブ
- [lib/discord/gateway_bot.rb](lib/discord/gateway_bot.rb): Gateway Botの更新版

**成果物**: メンションすると、Claudeが自然言語で応答するボット

**アーキテクチャ設計:**
```
Discord メンション
  ↓
Gateway Bot (lib/discord/gateway_bot.rb)
  ↓ 🤔 リアクション + ジョブキューに投入
DiscordLlmResponseJob (app/jobs/discord_llm_response_job.rb)
  ↓
LLM Provider (app/services/llm/)
  ├─ Base (抽象インターフェース)
  └─ Claude (Anthropic API)
  ↓
Discord API に返信
```

**LLMプロバイダーの抽象化:**
将来的に他のLLMプロバイダー(OpenAI, Geminiなど)に切り替え可能な設計になっています。

```ruby
# credentials.yml.enc で設定
llm:
  provider: "claude"  # "openai" や "gemini" に変更可能
```

新しいプロバイダーを追加する場合は、`app/services/llm/base.rb`を継承して実装するだけです:

```ruby
# 例: app/services/llm/openai.rb
module Llm
  class Openai < Base
    def generate(messages:, system_prompt: nil, temperature: 0.7, max_tokens: 1024)
      # OpenAI API実装
    end

    def provider_name
      :openai
    end
  end
end
```

---

### Phase 2: MVP完成 (2-3日)
1. Knowledgeモデル作成
2. 知見管理画面
3. 会話履歴の取得と利用
4. RAG: Knowledgeデータベース統合

### Phase 3: RAG強化 (1-2週間)
1. PostgreSQL全文検索
2. カテゴリー・タグフィルタリング
3. 使用統計

### Phase 4: 高度な機能
1. ベクトル検索
2. マルチターン会話
3. 画像対応

## コスト見積もり

- Claude API: 約$40/月 (100req/日)
- インフラ: 約$7/月
- 合計: 約$47/月

## セットアップ手順

### 1. Gemのインストール
```bash
bundle install
```

### 2. Credentials設定
```bash
EDITOR="vi" rails credentials:edit
```

以下を追加:
```yaml
anthropic:
  api_key: "sk-ant-api03-xxxxx"  # Anthropic Console (https://console.anthropic.com/) で取得

llm:
  provider: "claude"  # デフォルトのLLMプロバイダー
```

### 3. ローカル実行
```bash
# 3つのプロセスをそれぞれ別のターミナルで起動

# ターミナル1: Railsサーバー
rails server

# ターミナル2: ジョブワーカー
bin/jobs

# ターミナル3: Discord Gateway Bot
bin/discord_gateway
```

### 4. テスト
1. Discordサーバーでボットをメンション
2. ボットが🤔リアクションを返す
3. 数秒後、Claudeからの応答がスレッドに投稿される

### 5. 本番デプロイ (Heroku)
```bash
git push heroku main
heroku ps:scale discord_gateway=1
```

## 参考リンク

- Discord Developer Portal
- Anthropic API Docs
- discordrb gem

---

**作成者**: Claude (Anthropic)
**ステータス**: 設計完了
