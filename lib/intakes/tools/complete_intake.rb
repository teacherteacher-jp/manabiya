module Intakes
  module Tools
    class CompleteIntake
      def initialize(session)
        @session = session
      end

      def self.definition
        {
          name: "complete_intake",
          description: "すべての項目について情報を聞き出し終えたら、このツールを呼んで問診を完了してください。",
          input_schema: {
            type: "object",
            properties: {},
            required: []
          }
        }
      end

      def definition
        self.class.definition
      end

      def execute(_input)
        intake = @session.intake
        total_items = intake.intake_items.count
        recorded_items = @session.intake_responses.count

        if recorded_items < total_items
          missing = intake.intake_items
            .where.not(id: @session.intake_responses.select(:intake_item_id))
            .pluck(:name)
          return "まだ記録されていない項目があります: #{missing.join(', ')}"
        end

        @session.update!(status: :completed)

        # レポート生成
        Intakes::ReportGenerator.new(@session).generate

        "問診が完了しました。全#{total_items}項目の回答が記録され、報告書が生成されました。"
      rescue => e
        Rails.logger.error "CompleteIntake failed: #{e.class} - #{e.message}"
        "完了処理中にエラーが発生しました: #{e.message}"
      end
    end
  end
end
