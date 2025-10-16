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

### Phase 1: LLM統合 (1日) ✅ **完了!**
**目標**: Claudeを組み込んで自然な会話ができるボット

**タスク:**
1. ✅ anthropic gemを追加
2. ✅ LLMプロバイダー抽象化レイヤーの実装
   - `app/services/llm/base.rb`: 基底クラス
   - `app/services/llm/claude.rb`: Claude Sonnet 4.5実装
3. ✅ DiscordLlmResponseJob実装
4. ✅ GatewayBotをジョブキューに接続
5. ✅ credentials設定 (anthropic.api_key)
6. ✅ ローカルでテスト実行
7. ✅ デバッグとバグ修正
   - anthropic gem APIの更新対応
   - レスポンスパース処理の修正 (シンボル対応)
8. ✅ 指定チャンネルでの自動応答機能追加
   - メンションなしでも反応するチャンネルを設定可能に

**実装完了したファイル:**
- [app/services/llm/base.rb](app/services/llm/base.rb): LLMプロバイダーの抽象インターフェース
- [app/services/llm/claude.rb](app/services/llm/claude.rb): Claude Sonnet 4.5 API実装
- [app/jobs/discord_llm_response_job.rb](app/jobs/discord_llm_response_job.rb): Discord応答ジョブ
- [lib/discord/gateway_bot.rb](lib/discord/gateway_bot.rb): Gateway Botの更新版

**成果物**: メンションすると、Claude Sonnet 4.5が自然言語で丁寧に応答するボット

**使用モデル:**
- `claude-sonnet-4-5-20250929` (最新のClaude Sonnet 4.5)

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

**実装時に発生した問題と解決策:**

1. **問題**: `unknown keyword: :access_token`
   - **原因**: anthropic gem 1.11.0でAPIが変更され、`access_token`ではなく`api_key`を使用
   - **解決**: `Anthropic::Client.new(api_key: @api_key)`に修正

2. **問題**: `@client.messages(parameters: params)`が動作しない
   - **原因**: anthropic gem 1.11.0でAPIメソッドが変更
   - **解決**: `@client.messages.create(**params)`に修正

3. **問題**: Discord APIエラー "Cannot send an empty message"
   - **原因**: レスポンスの`type`がシンボル(`:text`)だが、文字列(`"text"`)で比較していた
   - **解決**: `block.type == :text`に修正してシンボル比較に対応

4. **問題**: credentialsを設定してもAPI keyが読み込まれない
   - **原因**: credentials変更後にプロセスを再起動していなかった
   - **解決**: すべてのプロセス(rails server, bin/jobs, bin/discord_gateway)を再起動

---

### Phase 2: MVP完成 (2-3日) 🎯 **← 次はここ!**
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

discord:
  community_help_channel_id: "1234567890"  # メンションなしで自動応答するチャンネルID
```

**自動応答チャンネルの設定:**
- `discord.community_help_channel_id`に指定したチャンネルでは、メンションなしでも全メッセージに反応します
- 未設定の場合は、メンション時のみ反応します（デフォルト動作）
- スレッド内でも同様に動作します（親チャンネルIDで判定）

**チャンネルIDの取得方法:**
1. Discordで開発者モードを有効化（ユーザー設定 → 詳細設定 → 開発者モード）
2. チャンネルを右クリック → IDをコピー

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

**パターン1: メンションでの応答（全チャンネル）**
1. Discordサーバーでボットをメンション
2. ボットが🤔リアクションを即座に返す
3. 数秒後、Claude Sonnet 4.5からの応答がスレッドに投稿される

**パターン2: メンションなしでの応答（指定チャンネルのみ）**
1. `discord.community_help_channel_id`で指定したチャンネルでメッセージを投稿
2. メンションなしでもボットが🤔リアクションを返す
3. 数秒後、Claude Sonnet 4.5からの応答がスレッドに投稿される

**期待される動作:**
- チャンネルでメンション → 自動でスレッドが作成され、その中で応答
- スレッド内でメンション → そのスレッド内で応答
- 指定チャンネルでのメッセージ → メンションなしでも応答（スレッド作成）
- ボット自身のメッセージには反応しない
- 応答時間: 約3-5秒

### 5. 本番デプロイ (Heroku)
```bash
git push heroku main
heroku ps:scale discord_gateway=1
```

## トラブルシューティング

### ボットが応答しない場合

1. **すべてのプロセスが起動しているか確認**
   ```bash
   # 3つのプロセスが必要
   rails server      # ターミナル1
   bin/jobs          # ターミナル2
   bin/discord_gateway  # ターミナル3
   ```

2. **ログを確認**
   ```bash
   # bin/jobsのターミナルでエラーログを確認
   # "DiscordLlmResponseJob started for thread: ..." が出ているか
   # "DiscordLlmResponseJob completed for thread: ..." が出ているか
   ```

3. **credentials設定を確認**
   ```bash
   EDITOR="cat" rails credentials:show
   # anthropic.api_key が設定されているか確認
   ```

4. **credentials変更後は必ず再起動**
   - すべてのプロセスをCtrl+Cで停止
   - 再度すべて起動

5. **Discord Bot権限を確認**
   - Send Messages
   - Send Messages in Threads
   - Read Message History

### よくあるエラー

- `ArgumentError: Anthropic API key is not configured`
  → credentials設定後、プロセスを再起動していない

- `unknown keyword: :access_token`
  → anthropic gem 1.11.0を使用しているか確認

- `Cannot send an empty message`
  → レスポンスパース処理の問題。`block.type == :text`になっているか確認

## 参考リンク

- [Discord Developer Portal](https://discord.com/developers/applications)
- [Anthropic API Docs](https://docs.anthropic.com/)
- [Anthropic Console (API Key取得)](https://console.anthropic.com/)
- [discordrb gem](https://github.com/shardlab/discordrb)
- [anthropic-sdk-ruby](https://github.com/anthropics/anthropic-sdk-ruby)
- [Claude Models Overview](https://docs.claude.com/en/docs/about-claude/models)

---

**作成者**: Claude (Anthropic)
**ステータス**: Phase 1完了 (2025-10-16)
**最終更新**: 2025-10-16
