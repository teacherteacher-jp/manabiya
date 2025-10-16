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

### Phase 1: MVP (2-3日)
1. discordrb, anthropic gemを追加
2. Knowledgeモデル作成
3. 知見管理画面
4. Gateway Bot実装
5. ClaudeResponseJob実装

### Phase 2: RAG強化 (1-2週間)
1. PostgreSQL全文検索
2. カテゴリー・タグフィルタリング
3. 使用統計

### Phase 3: 高度な機能
1. ベクトル検索
2. マルチターン会話
3. 画像対応

## コスト見積もり

- Claude API: 約$40/月 (100req/日)
- インフラ: 約$7/月
- 合計: 約$47/月

## デプロイ

```bash
bundle install
rails db:migrate
rails credentials:edit

# ローカル
rails server
bin/jobs
bin/discord_gateway

# 本番
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
