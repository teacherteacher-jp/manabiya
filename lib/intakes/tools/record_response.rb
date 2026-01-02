module Intakes
  module Tools
    class RecordResponse
      def initialize(session)
        @session = session
      end

      def self.definition
        {
          name: "record_response",
          description: "相談者から聞き出した情報を記録します。項目ごとに十分な情報が得られたら、このツールで記録してください。",
          input_schema: {
            type: "object",
            properties: {
              item_name: {
                type: "string",
                description: "記録する項目の名前（問診の項目名と一致させてください）"
              },
              content: {
                type: "string",
                description: "聞き出した内容のまとめ"
              }
            },
            required: %w[item_name content]
          }
        }
      end

      def definition
        self.class.definition
      end

      def execute(input)
        item_name = input["item_name"] || input[:item_name]
        content = input["content"] || input[:content]

        intake = @session.intake
        item = intake.intake_items.find_by(name: item_name)

        unless item
          return "エラー: 項目「#{item_name}」が見つかりません。有効な項目名: #{intake.intake_items.pluck(:name).join(', ')}"
        end

        existing = @session.intake_responses.find_by(intake_item: item)
        if existing
          existing.update!(content: content)
          "項目「#{item_name}」の回答を更新しました。"
        else
          @session.intake_responses.create!(intake_item: item, content: content)
          "項目「#{item_name}」の回答を記録しました。"
        end
      rescue => e
        Rails.logger.error "RecordResponse failed: #{e.class} - #{e.message}"
        "記録中にエラーが発生しました: #{e.message}"
      end
    end
  end
end
