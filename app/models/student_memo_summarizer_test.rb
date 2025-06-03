require 'ostruct'

class StudentMemoSummarizerTest
  def self.run_sample_test
    puts "=== StudentMemoSummarizer サンプルテスト開始 ==="

    begin
      # APIキーの確認
      api_key = Rails.application.credentials.openai.api_key
      if api_key.blank?
        puts "❌ エラー: OpenAI APIキーが設定されていません"
        return false
      end

      # サンプル生徒データ作成（テスト用）
      puts "📝 テスト用サンプルデータでのテスト..."

      summarizer = StudentMemoSummarizer.new

      # サンプル生徒オブジェクト（実際のDBには保存しない）
      sample_student = OpenStruct.new(
        id: 999,
        grade: "小学校3年生"
      )

      puts "✅ StudentMemoSummarizer初期化完了"
      puts "🎯 対象: Student:#{sample_student.id} (#{sample_student.grade})"
      puts "📅 期間: 2025年5月"
      puts ""

      # メモが存在しない場合のテスト
      puts "📄 メモなしパターンのテスト実行中..."
      no_memo_summary = summarizer.send(:generate_no_memo_summary, sample_student, 2025, 5)

      puts "✅ メモなしサマリー生成完了!"
      puts ""
      puts "=== メモなしサマリー ==="
      puts no_memo_summary
      puts ""
      puts "=== サンプルテスト完了 ==="

      true
    rescue => e
      puts "❌ エラーが発生しました: #{e.message}"
      puts e.backtrace.first(3)
      false
    end
  end

  def self.run_with_actual_student_test
    puts "=== StudentMemoSummarizer 実際の生徒データテスト開始 ==="

    begin
      # APIキーの確認
      api_key = Rails.application.credentials.openai.api_key
      if api_key.blank?
        puts "❌ エラー: OpenAI APIキーが設定されていません"
        return false
      end

      # 実際の生徒データを取得
      student = Student.first

      if student.nil?
        puts "❌ エラー: テスト用の生徒データが見つかりません"
        puts "💡 まず生徒データを作成してください"
        return false
      end

      summarizer = StudentMemoSummarizer.new

      puts "✅ StudentMemoSummarizer初期化完了"
      puts "🎯 対象: Student:#{student.id} (#{student.grade})"
      puts "🔗 #{Rails.application.routes.url_helpers.student_url(student)}"
      puts "📅 期間: 2025年5月"
      puts ""
      puts "📊 サマリー生成中..."

      summary = summarizer.generate_summary_for_student(
        student: student,
        year: 2025,
        month: 5,
        options: {
          max_tokens: 800,
          temperature: 0.7
        }
      )

      puts "✅ サマリー生成完了!"
      puts ""
      puts "=== 生成されたサマリー ==="
      puts summary
      puts ""
      puts "=== 実データテスト完了 ==="

      true
    rescue => e
      puts "❌ エラーが発生しました: #{e.message}"
      puts e.backtrace.first(3)
      false
    end
  end

  def self.run_memo_check
    puts "=== データベース状況確認 ==="

    student_count = Student.count
    memo_count = SchoolMemo.count

    puts "👥 生徒数: #{student_count}"
    puts "📝 メモ総数: #{memo_count}"

    if student_count > 0
      sample_student = Student.first
      puts ""
      puts "📋 サンプル生徒情報:"
      puts "  ID: #{sample_student.id}"
      puts "  学年: #{sample_student.grade}"

      # 2025年5月のメモをチェック
      may_memos = sample_student.school_memos.where(
        date: Date.new(2025, 5).beginning_of_month..Date.new(2025, 5).end_of_month
      )

      puts "  2025年5月のメモ数: #{may_memos.count}"

      if may_memos.any?
        puts "  📝 2025年5月のメモ例:"
        may_memos.limit(2).each do |memo|
          puts "    #{memo.date}: #{memo.content.truncate(50)}"
        end
      end
    end

    puts ""
    puts "=== 確認完了 ==="
  end
end
