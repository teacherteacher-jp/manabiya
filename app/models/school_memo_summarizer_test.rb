class SchoolMemoSummarizerTest
  def self.run_sample_test
    puts "=== SchoolMemoSummarizer テスト開始 ==="

    # サンプルのスクールメモデータ
    sample_memo_data = <<~DATA
      【2024年1月のスクールメモ】

      1月5日 田中太郎 (家庭から)
      算数の宿題を頑張って取り組んでいます。計算ミスが減ってきました。

      1月8日 佐藤花子 (学校から)
      友達との関係が良好で、積極的に発言するようになりました。

      1月12日 鈴木一郎 (ボランティアから)
      読書活動に集中して取り組んでいます。難しい本にも挑戦しています。

      1月15日 田中太郎 (家庭から)
      体調不良で2日間欠席しましたが、元気に登校再開しています。
    DATA

    begin
      puts "APIキーが設定されているかチェック中..."

      # APIキーの確認
      api_key = Rails.application.credentials.openai.api_key
      if api_key.blank?
        puts "❌ エラー: OpenAI APIキーが設定されていません"
        puts ""
        puts "設定方法:"
        puts "1. Rails credentials または環境変数でAPIキーを設定"
        puts "2. rails credentials:edit でopenai.api_keyを設定"
        puts ""
        return false
      end

      summarizer = SchoolMemoSummarizer.new

      puts "✅ APIキーが設定されています"
      puts ""
      puts "サマリー生成中..."

      summary = summarizer.generate_summary(
        content: sample_memo_data,
        options: {
          year: 2024,
          month: 1,
          max_tokens: 800,
          temperature: 0.7
        }
      )

      puts "✅ サマリー生成完了!"
      puts ""
      puts "=== 生成されたサマリー ==="
      puts summary
      puts ""
      puts "=== テスト完了 ==="

      true
    rescue => e
      puts "❌ エラーが発生しました: #{e.message}"
      puts ""
      puts "考えられる原因:"
      puts "- APIキーが無効"
      puts "- ネットワーク接続の問題"
      puts "- OpenAI APIの利用制限"
      puts ""
      false
    end
  end

  def self.run_openai_client_test
    puts "=== 汎用OpenAIクライアント テスト開始 ==="

    begin
      # APIキーの確認
      api_key = Rails.application.credentials.openai&.api_key || ENV['OPENAI_API_KEY']

      if api_key.blank?
        puts "❌ エラー: OpenAI APIキーが設定されていません"
        return false
      end

      client = OpenaiClient.new(api_key: api_key)

      puts "✅ APIキーが設定されています"
      puts ""
      puts "汎用チャット機能テスト中..."

      system_message = "あなたは親切なアシスタントです。"
      user_message = "「こんにちは」を3つの言語で言ってください。"

      response = client.chat(
        system_message: system_message,
        user_message: user_message,
        options: {
          max_tokens: 200,
          temperature: 0.7
        }
      )

      puts "✅ 汎用チャット機能テスト完了!"
      puts ""
      puts "=== レスポンス ==="
      puts response
      puts ""
      puts "=== テスト完了 ==="

      true
    rescue => e
      puts "❌ エラーが発生しました: #{e.message}"
      false
    end
  end
end
