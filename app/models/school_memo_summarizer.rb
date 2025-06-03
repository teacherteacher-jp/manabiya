class SchoolMemoSummarizer
  def initialize
    api_key = Rails.application.credentials.openai.api_key
    raise StandardError, "OpenAI APIキーが設定されていません" if api_key.blank?

    @openai_client = OpenaiClient.new(api_key: api_key)
  end

  def generate_summary(content:, options: {})
    raise ArgumentError, "Content cannot be blank" if content.blank?

    system_message = build_system_message
    user_message = build_user_message(content, options)

    @openai_client.chat(
      system_message: system_message,
      user_message: user_message,
      options: {
        model: "gpt-4o-mini",
        max_tokens: options[:max_tokens] || 1000,
        temperature: options[:temperature] || 0.7
      }
    )
  end

  def generate_summary_from_memos(school_memos, options: {})
    content = format_memos_for_summary(school_memos)
    generate_summary(content: content, options: options)
  end

  def api_key_configured?
    @openai_client&.api_key_configured?
  end

  private

  def build_system_message
    <<~MESSAGE
      あなたは教育現場の専門家です。
      スクールメモの内容を分析し、教育的観点から重要なポイントを整理したサマリーを作成してください。

      以下の観点で分析してください：
      1. 生徒の成長や学習状況
      2. 家庭との連携状況
      3. 支援が必要な事項
      4. 今後の注意点や改善提案

      出力はマークダウン形式で、構造化された読みやすい形式にしてください。
    MESSAGE
  end

  def build_user_message(content, options)
    year = options[:year]
    month = options[:month]
    period_text = year && month ? "#{year}年#{month}月の" : ""

    <<~PROMPT
      以下は#{period_text}スクールメモのデータです。
      このデータを基に、教育的な観点から重要なポイントを整理したサマリーを作成してください。

      【データ内容】
      #{content}

      【サマリー要件】
      - 月全体の傾向と特徴
      - 生徒個別の重要事項（成長、課題など）
      - カテゴリ（家庭・学校・ボランティア）別の分析
      - 今後の注意点や改善提案

      教育関係者が理解しやすい構造で、マークダウン形式で出力してください。
    PROMPT
  end

  def format_memos_for_summary(school_memos)
    school_memos.map do |memo|
      student_names = memo.students.pluck(:name).join(", ")
      "#{memo.date} #{student_names} (#{memo.category})\n#{memo.content}"
    end.join("\n\n")
  end
end
