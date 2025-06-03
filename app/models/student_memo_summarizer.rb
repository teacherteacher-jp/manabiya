class StudentMemoSummarizer
  def initialize
    api_key = Rails.application.credentials.openai.api_key
    raise StandardError, "OpenAI APIキーが設定されていません" if api_key.blank?

    @openai_client = OpenaiClient.new(api_key: api_key)
  end

  def generate_summary_for_student(student:, year:, month:, options: {})
    raise ArgumentError, "Student is required" unless student
    raise ArgumentError, "Year is required" unless year
    raise ArgumentError, "Month is required" unless month

    # 対象期間のメモを取得
    memos = fetch_student_memos(student, year, month)

    if memos.empty?
      return generate_no_memo_summary(student, year, month)
    end

    # 匿名化されたコンテンツを生成
    anonymized_content = format_anonymized_memos(student, memos)

    system_message = build_system_message
    user_message = build_user_message(student, anonymized_content, year, month)

    @openai_client.chat(
      system_message: system_message,
      user_message: user_message,
      options: {
        model: "gpt-4o-mini",
        max_tokens: options[:max_tokens] || 800,
        temperature: options[:temperature] || 0.7
      }
    )
  end

  def api_key_configured?
    @openai_client&.api_key_configured?
  end

  private

  def fetch_student_memos(student, year, month)
    start_date = Date.new(year, month).beginning_of_month
    end_date = Date.new(year, month).end_of_month

    student.school_memos
           .where(date: start_date..end_date)
           .includes(:member)
           .order(:date)
  end

  def format_anonymized_memos(student, memos)
    anonymized_student_name = "Student:#{student.id} (#{student.grade})"

    memos.map do |memo|
      "#{memo.date} #{anonymized_student_name} (#{memo.category})\n#{memo.content}"
    end.join("\n\n")
  end

  def build_system_message
    <<~MESSAGE
      あなたは教育現場の専門家です。
      特定の生徒の月次メモを分析し、その生徒の成長、学習状況、課題を教育的観点から整理したサマリーを作成してください。

      以下の観点で分析してください：
      1. 学習面での成長と課題
      2. 生活面・行動面での変化
      3. 家庭・学校・ボランティアからの情報の統合
      4. 今後の支援方針や注意点

      個人の成長に焦点を当てた、建設的で前向きな分析を心がけてください。
      出力はマークダウン形式で、構造化された読みやすい形式にしてください。
    MESSAGE
  end

  def build_user_message(student, content, year, month)
    anonymized_student_name = "Student:#{student.id} (#{student.grade})"

    <<~PROMPT
      以下は#{anonymized_student_name}の#{year}年#{month}月のスクールメモです。
      この生徒の月間の成長、学習状況、課題について詳細な分析を行ってください。

      【対象生徒】#{anonymized_student_name}
      【対象期間】#{year}年#{month}月

      【メモ内容】
      #{content}

      【分析要件】
      - 学習面での成長ポイント
      - 生活面・行動面での変化
      - 各情報源（家庭・学校・ボランティア）からの総合的な見解
      - 今後の重点支援項目
      - 来月以降の注意点や目標提案

      教育関係者が個別指導に活用できる具体的で実用的な内容で、マークダウン形式で出力してください。
    PROMPT
  end

  def generate_no_memo_summary(student, year, month)
    anonymized_student_name = "Student:#{student.id} (#{student.grade})"

    <<~SUMMARY
      # #{anonymized_student_name} - #{year}年#{month}月 サマリー

      ## 📝 メモ状況
      **#{year}年#{month}月は記録されたメモがありません。**

      ## 💡 推奨アクション
      - 定期的な観察とメモ記録の検討
      - 家庭・学校・ボランティアとの連携強化
      - 次月からの積極的な情報収集

      ---
      *継続的な観察と記録により、より詳細な分析が可能になります。*
    SUMMARY
  end
end
